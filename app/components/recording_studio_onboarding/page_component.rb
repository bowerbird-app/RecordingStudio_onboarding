# frozen_string_literal: true

module RecordingStudioOnboarding
  # Default onboarding page body: optional splash or top image, title, HTML content.
  # When both splash_image_url and image_url are set, splash wins.
  class PageComponent < BaseCardComponent
    attr_reader :title, :content_html, :splash_image_url, :image_url, :image_alt

    # `content:` is a reserved ViewComponent initializer name; pass the HTML
    # body as `content:` via **fields (or `body:`) so hosts can still say content.
    def initialize( # rubocop:disable Metrics/ParameterLists
      run:,
      step:,
      title: nil,
      splash_image_url: nil,
      image_url: nil,
      image_alt: nil,
      **fields
    )
      super(run: run, step: step)
      @title = title
      @content_html = fields.delete(:content) || fields.delete(:body)
      if fields.any?
        raise ArgumentError, "Unknown page fields: #{fields.keys.map(&:inspect).join(', ')}"
      end

      @splash_image_url = sanitize_url(splash_image_url)
      @image_url = sanitize_url(image_url)
      @image_alt = image_alt.presence || title.to_s
    end

    def call
      if splash?
        render_splash
      elsif top_image?
        render_top_image
      else
        render_plain
      end
    end

    private

    def splash?
      @splash_image_url.present?
    end

    def top_image?
      @image_url.present?
    end

    def sanitize_url(url)
      return if url.blank?

      FlatPack::AttributeSanitizer.sanitize_url(url)
    end

    def render_splash
      content_tag(
        :div,
        class: "relative flex min-h-[28rem] w-full flex-col justify-end overflow-hidden " \
               "rounded-[var(--radius-md)] sm:min-h-[32rem]",
        data: { testid: "onboarding-page", layout: "splash" }
      ) do
        safe_join(
          [
            helpers.image_tag(
              @splash_image_url,
              alt: "",
              class: "absolute inset-0 h-full w-full object-cover",
              "aria-hidden": "true"
            ),
            content_tag(
              :div,
              nil,
              class: "pointer-events-none absolute inset-0 " \
                     "bg-gradient-to-t from-black/80 via-black/45 to-black/20",
              "aria-hidden": "true"
            ),
            content_tag(
              :div,
              class: "relative z-10 flex w-full flex-col gap-3 p-6 sm:p-8 " \
                     "text-[var(--surface-page-background-color)]"
            ) do
              copy_blocks(on_dark: true)
            end
          ]
        )
      end
    end

    def render_top_image
      content_tag(
        :div,
        class: "flex w-full flex-col gap-5",
        data: { testid: "onboarding-page", layout: "top-card" }
      ) do
        safe_join(
          [
            content_tag(
              :div,
              class: "w-full overflow-hidden rounded-b-[var(--radius-lg)] " \
                     "bg-[var(--surface-muted-background-color)]"
            ) do
              helpers.image_tag(
                @image_url,
                alt: @image_alt,
                class: "block h-56 w-full object-cover sm:h-72"
              )
            end,
            content_tag(:div, class: "flex w-full flex-col gap-3") { copy_blocks(on_dark: false) }
          ]
        )
      end
    end

    def render_plain
      content_tag(
        :div,
        class: "flex w-full flex-col gap-3",
        data: { testid: "onboarding-page", layout: "plain" }
      ) do
        copy_blocks(on_dark: false)
      end
    end

    def copy_blocks(on_dark:)
      parts = []
      if @title.present?
        parts << render(
          FlatPack::PageTitle::Component.new(
            title: @title,
            variant: :h1,
            title_color: (on_dark ? "var(--surface-page-background-color)" : nil),
            subtitle_color: (on_dark ? "var(--surface-page-background-color)" : nil)
          )
        )
      end
      parts << rich_content(on_dark: on_dark) if @content_html.present?
      safe_join(parts)
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
