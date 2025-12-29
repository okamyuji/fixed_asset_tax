import type { FixedAsset, FixedAssetCreateRequest, FixedAssetUpdateRequest } from '../types';
import { apiClient } from './client';

export const fixedAssetsApi = {
    list: async (tenantId: string, propertyId?: number): Promise<FixedAsset[]> => {
        const response = await apiClient.get<FixedAsset[]>('/fixed_assets', {
            params: { tenant_id: tenantId, property_id: propertyId },
        });
        return response.data;
    },

    get: async (id: number, tenantId: string): Promise<FixedAsset> => {
        const response = await apiClient.get<FixedAsset>(`/fixed_assets/${id}`, {
            params: { tenant_id: tenantId },
        });
        return response.data;
    },

    create: async (data: FixedAssetCreateRequest, tenantId: string): Promise<FixedAsset> => {
        const response = await apiClient.post<FixedAsset>('/fixed_assets', {
            ...data,
            tenant_id: tenantId,
        });
        return response.data;
    },

    update: async (id: number, data: FixedAssetUpdateRequest, tenantId: string): Promise<FixedAsset> => {
        const response = await apiClient.put<FixedAsset>(`/fixed_assets/${id}`, {
            ...data,
            tenant_id: tenantId,
        });
        return response.data;
    },

    delete: async (id: number, tenantId: string): Promise<void> => {
        await apiClient.delete(`/fixed_assets/${id}`, {
            params: { tenant_id: tenantId },
        });
    },
};
