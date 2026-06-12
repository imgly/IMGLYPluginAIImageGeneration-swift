import Foundation
import UIKit

/// Maximum source-image dimension (px) before we resize prior to upload.
/// Picked to match the documented input limit (1820 px on either axis).
private let maxSourceImageDimension: CGFloat = 1820

/// Explicit request timeout. The default `URLSession` 60 s is too tight for
/// the SSE generation endpoint on slow networks; 120 s gives us a margin
/// while still failing fast enough to surface real problems.
private let gatewayRequestTimeout: TimeInterval = 120

// MARK: - Models

/// IMG.LY Gateway image model family.
///
/// Pass one of these cases as the `model` parameter of ``AIGatewayService``
/// to select which model the gateway routes generation requests to.
///
/// To add a new family, confirm the model IDs are in your API key's scopes
/// (manage keys in the IMG.LY Dashboard: https://img.ly/dashboard), then add
/// a case below and extend the internal model-id/request-body switches.
public enum AIGatewayImageModel: Sendable {
  /// FLUX.2 by Black Forest Labs.
  /// - text-to-image: `bfl/flux-2`
  /// - image-to-image: `bfl/flux-2-edit`
  case fluxV2

  /// GPT Image 2 by OpenAI.
  /// - text-to-image: `openai/gpt-image-2`
  /// - image-to-image: `openai/gpt-image-2-edit`
  case gptImage2

  var textToImageId: String {
    switch self {
    case .fluxV2: "bfl/flux-2"
    case .gptImage2: "openai/gpt-image-2"
    }
  }

  var imageToImageId: String {
    switch self {
    case .fluxV2: "bfl/flux-2-edit"
    case .gptImage2: "openai/gpt-image-2-edit"
    }
  }

  /// Build the `input` payload for `POST /v1/responses` for this model.
  func buildRequestInput(
    prompt: String,
    size: ImageSize?,
    imageURLs: [String]?,
  ) -> [String: Any] {
    var input: [String: Any] = ["prompt": prompt]
    if let urls = imageURLs, !urls.isEmpty {
      input["image_urls"] = urls
    }

    switch self {
    case .fluxV2, .gptImage2:
      if let size {
        input["format"] = Self.dimensionFormat(for: size)
      }
      return input
    }
  }

  /// Build a `{width, height}` dictionary clamped to the gateway's 1–2048
  /// per-dimension limit.
  private static func dimensionFormat(for size: ImageSize) -> [String: Int] {
    let dims = size.dimensions
    return [
      "width": max(1, min(2048, dims.width)),
      "height": max(1, min(2048, dims.height)),
    ]
  }
}

// MARK: - Response shapes

private struct CompletedEventOutput: Decodable { let url: String }

private struct CompletedEvent: Decodable {
  let output: [CompletedEventOutput]
}

private struct UploadMetadata: Decodable {
  let uploadURL: String
  let assetURL: String

  enum CodingKeys: String, CodingKey {
    case uploadURL = "upload_url"
    case assetURL = "asset_url"
  }
}

// MARK: - AIGatewayService

/// IMG.LY Gateway image generation service.
///
/// Speaks to `https://gateway.img.ly` directly via `URLSession` + SSE.
/// No third-party SDK required. Handles both text-to-image and
/// image-to-image by switching the model id based on whether the request
/// carries a source image.
///
/// Style support is **prompt-engineered**: if the request carries a
/// ``PromptStyle``, the service appends its `promptSnippet` to the user's
/// prompt before calling the model.
public final class AIGatewayService: AIImageService {
  // MARK: - Properties

  private let apiKey: String
  private let model: AIGatewayImageModel
  private let gatewayURL: URL

  // MARK: - Initialization

  /// Creates a gateway service.
  /// - Parameters:
  ///   - apiKey: IMG.LY Gateway API key (`sk_…`). Obtain one from the IMG.LY Dashboard.
  ///   - model: The model family to use for generation.
  ///   - gatewayURL: Base URL of the IMG.LY Gateway.
  public init(
    apiKey: String,
    model: AIGatewayImageModel = .fluxV2,
    // swiftlint:disable:next force_unwrapping
    gatewayURL: URL = URL(string: "https://gateway.img.ly")!,
  ) {
    self.apiKey = apiKey
    self.model = model
    self.gatewayURL = gatewayURL
  }

  // MARK: - AIImageService

  public func generateImage(
    with request: ImageGenerationRequest,
  ) async throws -> GeneratedImage {
    guard !request.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw AIServiceError.invalidRequest("Prompt must not be empty")
    }

    let isImageToImage = request.sourceImageData != nil || request.sourceImageURL != nil
    let modelId = isImageToImage ? model.imageToImageId : model.textToImageId
    let startTime = Date()

    // Append the selected style's snippet to the user's prompt.
    let finalPrompt: String = {
      guard let snippet = request.selectedStyle?.promptSnippet,
            !snippet.isEmpty else {
        return request.prompt
      }
      return "\(request.prompt); \(snippet)"
    }()

    // Resolve image inputs: upload local bytes via /v1/uploads, otherwise
    // pass a remote URL through.
    var imageURLs: [String]?
    if let sourceData = request.sourceImageData {
      let prepared = try prepareImageForUpload(sourceData)
      let assetURL = try await uploadImage(prepared, mimeType: "image/jpeg")
      imageURLs = [assetURL]
    } else if let sourceURL = request.sourceImageURL {
      imageURLs = [sourceURL.absoluteString]
    }

    let input = model.buildRequestInput(
      prompt: finalPrompt, size: request.size, imageURLs: imageURLs,
    )

    let url = try await postAndStream(model: modelId, input: input)

    return GeneratedImage(
      imageURL: url,
      metadata: ImageMetadata(
        generationTime: Date().timeIntervalSince(startTime),
        serviceUsed: "IMG.LY Gateway - \(modelId)",
      ),
    )
  }

  // MARK: - HTTP / SSE

  private func postAndStream(
    model: String,
    input: [String: Any],
  ) async throws -> URL {
    var body = input
    body["model"] = model
    let bodyData = try JSONSerialization.data(withJSONObject: body)
    let url = gatewayURL.appendingPathComponent("v1/responses")

    var request = URLRequest(url: url, timeoutInterval: gatewayRequestTimeout)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
    request.httpBody = bodyData

    let (bytes, response) = try await URLSession.shared.bytes(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw AIServiceError.generationFailed("Non-HTTP response from gateway")
    }

    if !(200 ..< 300).contains(http.statusCode) {
      let bodyText = await readBoundedBody(bytes)
      throw AIServiceError.generationFailed(
        "Gateway returned HTTP \(http.statusCode): \(bodyText)",
      )
    }

    var currentEvent = ""
    for try await line in bytes.lines {
      try Task.checkCancellation()
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if trimmed.isEmpty || trimmed.hasPrefix(":") { continue }

      if trimmed.hasPrefix("event:") {
        currentEvent = String(trimmed.dropFirst("event:".count))
          .trimmingCharacters(in: .whitespaces)
        continue
      }

      guard trimmed.hasPrefix("data:") else { continue }
      let payload = String(trimmed.dropFirst("data:".count))
        .trimmingCharacters(in: .whitespaces)
      guard let data = payload.data(using: .utf8) else { continue }

      switch currentEvent {
      case "generation.completed":
        return try parseCompletedEvent(data)
      case "generation.failed":
        throw AIServiceError.generationFailed(parseFailedMessage(data))
      default:
        break
      }
      currentEvent = ""
    }

    throw AIServiceError.generationFailed("Stream ended without a completion event")
  }

  // MARK: - SSE event decoding

  private func parseCompletedEvent(_ data: Data) throws -> URL {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let event = try decoder.decode(CompletedEvent.self, from: data)
    guard let urlString = event.output.first?.url, let url = URL(string: urlString) else {
      throw AIServiceError.generationFailed("Completion event contained no usable image URL")
    }
    return url
  }

  private func parseFailedMessage(_ data: Data) -> String {
    if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let err = dict["error"] as? [String: Any],
       let msg = err["message"] as? String {
      return msg
    }
    return "Generation failed"
  }

  // MARK: - Upload (two-step presigned PUT)

  private func uploadImage(
    _ data: Data,
    mimeType: String,
  ) async throws -> String {
    // Step 1 — request a presigned upload URL.
    let metadataURL = gatewayURL.appendingPathComponent("v1/uploads")
    var metadataRequest = URLRequest(url: metadataURL, timeoutInterval: gatewayRequestTimeout)
    metadataRequest.httpMethod = "POST"
    metadataRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    metadataRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    metadataRequest.httpBody = try JSONSerialization.data(
      withJSONObject: ["content_type": mimeType],
    )

    let (metadataData, metadataResponse) = try await URLSession.shared.data(for: metadataRequest)
    guard let metadataHTTP = metadataResponse as? HTTPURLResponse else {
      throw AIServiceError.generationFailed("Non-HTTP response from gateway")
    }
    if !(200 ..< 300).contains(metadataHTTP.statusCode) {
      let metadataBody = String(data: metadataData, encoding: .utf8) ?? ""
      throw AIServiceError.generationFailed(
        "Gateway upload metadata HTTP \(metadataHTTP.statusCode): \(metadataBody)",
      )
    }

    let metadata: UploadMetadata
    do {
      metadata = try JSONDecoder().decode(UploadMetadata.self, from: metadataData)
    } catch {
      throw AIServiceError.generationFailed("Failed to decode upload metadata: \(error)")
    }

    // Step 2 — PUT the bytes to the presigned URL (no auth header).
    try Task.checkCancellation()
    guard let uploadURL = URL(string: metadata.uploadURL) else {
      throw AIServiceError.generationFailed("Gateway returned an invalid upload_url")
    }
    var putRequest = URLRequest(url: uploadURL, timeoutInterval: gatewayRequestTimeout)
    putRequest.httpMethod = "PUT"
    putRequest.setValue(mimeType, forHTTPHeaderField: "Content-Type")
    putRequest.httpBody = data

    let (putBody, putResponse) = try await URLSession.shared.data(for: putRequest)
    if let putHTTP = putResponse as? HTTPURLResponse {
      if !(200 ..< 300).contains(putHTTP.statusCode) {
        let putBodyText = String(data: putBody, encoding: .utf8) ?? "<non-utf8>"
        throw AIServiceError.generationFailed(
          "Presigned PUT failed with HTTP \(putHTTP.statusCode): \(putBodyText)",
        )
      }
    }

    return metadata.assetURL
  }

  // MARK: - Image preprocessing

  private func prepareImageForUpload(_ data: Data) throws -> Data {
    guard let image = UIImage(data: data) else {
      throw AIServiceError.invalidRequest("Source image data is not a valid image")
    }
    let resized = resize(image, maxDimension: maxSourceImageDimension)
    guard let jpegData = resized.jpegData(compressionQuality: 0.85) else {
      throw AIServiceError.generationFailed("Failed to encode image as JPEG")
    }
    return jpegData
  }

  private func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
    let pixelWidth = image.size.width * image.scale
    let pixelHeight = image.size.height * image.scale
    let scale = min(maxDimension / pixelWidth, maxDimension / pixelHeight, 1.0)
    if scale >= 1.0 { return image }

    let newSize = CGSize(width: pixelWidth * scale, height: pixelHeight * scale)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1.0
    return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
      image.draw(in: CGRect(origin: .zero, size: newSize))
    }
  }

  // MARK: - Helpers

  private func readBoundedBody(_ bytes: URLSession.AsyncBytes) async -> String {
    var data = Data()
    let cap = 4096
    do {
      for try await byte in bytes {
        data.append(byte)
        if data.count >= cap { break }
      }
    } catch {}
    return String(data: data, encoding: .utf8) ?? ""
  }
}
