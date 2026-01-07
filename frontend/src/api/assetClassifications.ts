import type { AssetClassificationsResponse } from "../types";
import { apiClient } from "./client";

export const assetClassificationsApi = {
	getAll: async (): Promise<AssetClassificationsResponse> => {
		const response = await apiClient.get("/asset_classifications");
		return response.data;
	},

	getAccountItems: async () => {
		const response = await apiClient.get(
			"/asset_classifications/account_items",
		);
		return response.data;
	},

	getUsefulLife: async (
		accountItem: string,
	): Promise<{ account_item: string; useful_life_years: number | null }> => {
		const response = await apiClient.get("/asset_classifications/useful_life", {
			params: { account_item: accountItem },
		});
		return response.data;
	},
};
