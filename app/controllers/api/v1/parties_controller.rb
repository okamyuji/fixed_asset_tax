module Api
  module V1
    class PartiesController < BaseController
      before_action :set_party, only: [ :show, :update, :destroy ]

      def index
        parties = current_tenant.parties
        render json: parties.map { |p| party_response(p) }
      end

      def show
        render json: party_response(@party)
      end

      def create
        party = current_tenant.parties.build(party_params)

        if party.save
          render json: party_response(party), status: :created
        else
          render json: { errors: party.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @party.update(party_params)
          render json: party_response(@party)
        else
          render json: { errors: @party.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @party.destroy
        head :no_content
      end

      private

      def set_party
        @party = current_tenant.parties.find(params[:id])
      end

      def party_params
        params.require(:party).permit(:type, :display_name, :birth_date, :corporate_number)
      end

      def party_response(party)
        {
          id: party.id,
          type: party.type,
          display_name: party.display_name,
          birth_date: party.birth_date,
          corporate_number: party.corporate_number,
          created_at: party.created_at,
          updated_at: party.updated_at
        }
      end
    end
  end
end
