# frozen_string_literal: true

module RecordingStudioOnboarding
  # Default onboarding page body: optional splash or top image, title, HTML content.
  # When both splash_image_url and image_url are set, splash wins.
  class PageComponent < BaseCardComponent
    attr_reader :title, :content_html, :splash_image_url, :image_url, :image_alt

    # `content:` is reserved by ViewComponent; pass HTML via **fields (`content:` / `body:`).
    def initialize(run:, step:, title: nil, splash_image_url: nil, image_url: nil, image_alt: nil, **fields) # rubocop:disable Metrics/ParameterLists
      super(run: run, step: step)
      @title = title
      @content_html = fields.delete(:content) || fields.delete(:body)
      raise ArgumentError, "Unknown page fields: #{fields.keys.map(&:inspect).join(', ')}" if fields.any?

      @splash_image_url = sanitize_url(splash_image_url)
      @image_url = sanitize_url(image_url)
      @image_alt = image_alt.presence || title.to_s
    end

    def call
      return render_splash if splash?
      return render_top_image if top_image?

      render_plain
    end

    private

    def splash? = @splash_image_url.present?
    def top_image? = @image_url.present?

    def sanitize_url(url)
      FlatPack::AttributeSanitizer.sanitize_url(url) if url.present?
    end

    def render_splash
      page_shell("splash", "relative flex min-h-[28rem] w-full flex-col justify-end overflow-hidden " \
                           "rounded-[var(--radius-md)] sm:min-h-[32rem]") do
        safe_join([splash_image, splash_tint, splash_copy])
      end
    end

    def splash_image
      helpers.image_tag(
        @splash_image_url, alt: "", class: "absolute inset-0 h-full w-full object-cover",
                           "aria-hidden": "true"
      )
    end

    def splash_tint
      content_tag(
        :div, nil, "aria-hidden": "true",
                   class: "pointer-events-none absolute inset-0 bg-gradient-to-t from-black/80 via-black/45 to-black/20"
      )
    end

    def splash_copy
      content_tag(
        :div,
        class: "relative z-10 flex w-full flex-col gap-3 p-6 sm:p-8 text-[var(--surface-page-background-color)]"
      ) { copy_blocks(on_dark: true) }
    end

    def render_top_image
      page_shell("top-card", "flex w-full flex-col gap-5") do
        safe_join([top_image_frame, copy_wrap { copy_blocks(on_dark: false) }])
      end
    end

    def top_image_frame
      content_tag(
        :div,
        class: "w-full overflow-hidden rounded-b-[var(--radius-lg)] bg-[var(--surface-muted-background-color)]"
      ) { helpers.image_tag(@image_url, alt: @image_alt, class: "block h-56 w-full object-cover sm:h-72") }
    end

    def render_plain
      page_shell("plain", "flex w-full flex-col gap-3") { copy_blocks(on_dark: false) }
    end

    def page_shell(layout, classes, &)
      content_tag(:div, class: classes, data: { testid: "onboarding-page", layout: layout }, &)
    end

    def copy_wrap(&)
      content_tag(:div, class: "flex w-full flex-col gap-3", &)
    end

    def copy_blocks(on_dark:)
      parts = []
      parts << page_title(on_dark) if @title.present?
      parts << rich_content(on_dark: on_dark) if @content_html.present?
      safe_join(parts)
    end

    def page_title(on_dark)
      color = on_dark ? "var(--surface-page-background-color)" : nil
      render FlatPack::PageTitle::Component.new(
        title: @title, variant: :h1, title_color: color, subtitle_color: color
      )
    end

    def rich_content(on_dark:)
      tone = on_dark ? "text-[var(--surface-page-background-color)]/90" : ""
      content_tag(:div, class: "text-base leading-7 #{tone}".strip, data: { testid: "onboarding-page-content" }) do
        helpers.sanitize(
          @content_html.to_s,
          tags: %w[p br strong em a ul ol li h2 h3 span],
          attributes: %w[href target rel class]
        )
      end
    end
  end
end
