import Foundation
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

extension LocalizationTable {
  static let imglyPluginAIImageGeneration = LocalizationTable(
    table: "IMGLYPluginAIImageGeneration",
    bundle: .module,
  )
}

// swiftlint:disable identifier_name
extension LocalizedStringResource {
  // MARK: - Buttons

  static let aiImageGeneration_buttonAddImageOptional: LocalizedStringResource = .imgly
    .localized(
      "ly_img_plugin_ai_image_generation_button_add_image_optional",
      table: .imglyPluginAIImageGeneration,
    )

  static let aiImageGeneration_buttonApply: LocalizedStringResource = .imgly
    .localized(
      "ly_img_plugin_ai_image_generation_button_apply",
      table: .imglyPluginAIImageGeneration,
    )

  static let aiImageGeneration_buttonCancel: LocalizedStringResource = .imgly
    .localized(
      "ly_img_plugin_ai_image_generation_button_cancel",
      table: .imglyPluginAIImageGeneration,
    )

  static let aiImageGeneration_buttonDone: LocalizedStringResource = .imgly
    .localized(
      "ly_img_plugin_ai_image_generation_button_done",
      table: .imglyPluginAIImageGeneration,
    )

  static let aiImageGeneration_buttonGenerate: LocalizedStringResource = .imgly
    .localized(
      "ly_img_plugin_ai_image_generation_button_generate",
      table: .imglyPluginAIImageGeneration,
    )

  static let aiImageGeneration_buttonMakeIt: LocalizedStringResource = .imgly
    .localized(
      "ly_img_plugin_ai_image_generation_button_make_it",
      table: .imglyPluginAIImageGeneration,
    )

  static let aiImageGeneration_buttonEdit: LocalizedStringResource = .imgly
    .localized(
      "ly_img_plugin_ai_image_generation_button_edit",
      table: .imglyPluginAIImageGeneration,
    )

  // MARK: - Labels

  static let aiImageGeneration_labelCustomSize: LocalizedStringResource = .imgly
    .localized(
      "ly_img_plugin_ai_image_generation_label_custom_size",
      table: .imglyPluginAIImageGeneration,
    )

  static let aiImageGeneration_labelFormat: LocalizedStringResource = .imgly
    .localized(
      "ly_img_plugin_ai_image_generation_label_format",
      table: .imglyPluginAIImageGeneration,
    )

  static let aiImageGeneration_labelImageStyle: LocalizedStringResource = .imgly
    .localized(
      "ly_img_plugin_ai_image_generation_label_image_style",
      table: .imglyPluginAIImageGeneration,
    )

  static let aiImageGeneration_textImageHeightPx: LocalizedStringResource = .imgly
    .localized(
      "ly_img_plugin_ai_image_generation_text_image_height_px",
      table: .imglyPluginAIImageGeneration,
    )

  static let aiImageGeneration_textImageWidthPx: LocalizedStringResource = .imgly
    .localized(
      "ly_img_plugin_ai_image_generation_text_image_width_px",
      table: .imglyPluginAIImageGeneration,
    )

  // MARK: - Placeholder

  static let aiImageGeneration_placeholderPrompt: LocalizedStringResource = .imgly
    .localized(
      "ly_img_plugin_ai_image_generation_placeholder_prompt",
      table: .imglyPluginAIImageGeneration,
    )

  // MARK: - Titles

  static let aiImageGeneration_titleAIImageGeneration: LocalizedStringResource = .imgly
    .localized(
      "ly_img_plugin_ai_image_generation_title_ai_image_generation",
      table: .imglyPluginAIImageGeneration,
    )

  static let aiImageGeneration_titleSelectStyle: LocalizedStringResource = .imgly
    .localized(
      "ly_img_plugin_ai_image_generation_title_select_style",
      table: .imglyPluginAIImageGeneration,
    )
}

// swiftlint:enable identifier_name
