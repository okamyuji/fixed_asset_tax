import type { CalculationResult, CalculationRun, CalculationRunCreateRequest } from '../types';
import { apiClient } from './client';

export const calculationsApi = {
    list: async (tenantId: string): Promise<CalculationRun[]> => {
        const response = await apiClient.get<CalculationRun[]>('/calculation_runs', {
            params: { tenant_id: tenantId },
        });
        return response.data;
    },

    get: async (id: number, tenantId: string): Promise<CalculationRun> => {
        const response = await apiClient.get<CalculationRun>(`/calculation_runs/${id}`, {
            params: { tenant_id: tenantId },
        });
        return response.data;
    },

    create: async (data: CalculationRunCreateRequest, tenantId: string): Promise<CalculationRun> => {
        const response = await apiClient.post<CalculationRun>('/calculation_runs', {
            ...data,
            tenant_id: tenantId,
        });
        return response.data;
    },

    execute: async (id: number, tenantId: string): Promise<void> => {
        await apiClient.post(`/calculation_runs/${id}/execute`, {
            tenant_id: tenantId,
        });
    },

    getResults: async (id: number, tenantId: string): Promise<CalculationResult[]> => {
        const response = await apiClient.get<CalculationResult[]>(`/calculation_runs/${id}/results`, {
            params: { tenant_id: tenantId },
        });
        return response.data;
    },
};
