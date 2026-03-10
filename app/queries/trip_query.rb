class TripQuery
    DEFAULT_PER_PAGE = 10

    def initialize(params = {})
        @params = params
    end

    def call
        scope = Trip.all
        scope = apply_search(scope)
        scope = apply_min_rating(scope)
        scope = apply_sort(scope)
        apply_pagination(scope)
    end

    private

    attr_reader :params

    def apply_search(scope)
        return scope if params[:search].blank?

        scope.where("LOWER(name) LIKE ?", "%#{params[:search].downcase}%")
    end

    def apply_min_rating(scope)
        return scope if params[:min_rating].blank?

        scope.where("rating >= ?", params[:min_rating].to_i)
    end

    def apply_sort(scope)
        case params[:sort]
        when "rating_asc" then scope.order(rating: :asc)
        when "rating_desc" then scope.order(rating: :desc)
        else scope.order(:name)
        end
    end

    def apply_pagination(scope)
        per_page = params[:per_page].present? ? params[:per_page].to_i : DEFAULT_PER_PAGE
        page = params[:page].present? ? params[:page].to_i : 1

        scope.page(page).per(per_page)
    end
end
