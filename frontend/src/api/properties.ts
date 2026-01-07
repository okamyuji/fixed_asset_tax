import type {
	Property,
	PropertyCreateRequest,
	PropertyUpdateRequest,
} from "../types";
import { apiClient } from "./client";

export const propertiesApi = {
	list: async (tenantId: string): Promise<Property[]> => {
		const response = await apiClient.get<Property[]>("/properties", {
			params: { tenant_id: tenantId },
		});
		return response.data;
	},

	get: async (id: number, tenantId: string): Promise<Property> => {
		const response = await apiClient.get<Property>(`/properties/${id}`, {
			params: { tenant_id: tenantId },
		});
		return response.data;
	},

	create: async (
		data: PropertyCreateRequest,
		tenantId: string,
	): Promise<Property> => {
		const response = await apiClient.post<Property>("/properties", {
			...data,
			tenant_id: tenantId,
		});
		return response.data;
	},

	update: async (
		id: number,
		data: PropertyUpdateRequest,
		tenantId: string,
	): Promise<Property> => {
		const response = await apiClient.put<Property>(`/properties/${id}`, {
			...data,
			tenant_id: tenantId,
		});
		return response.data;
	},

	delete: async (id: number, tenantId: string): Promise<void> => {
		await apiClient.delete(`/properties/${id}`, {
			params: { tenant_id: tenantId },
		});
	},
};
