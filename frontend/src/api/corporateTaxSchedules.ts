import type { CorporateTaxSchedule, CorporateTaxScheduleCreateRequest } from '../types';
import { apiClient } from './client';

export const corporateTaxSchedulesApi = {
  getAll: async (): Promise<CorporateTaxSchedule[]> => {
    const response = await apiClient.get('/corporate_tax_schedules');
    return response.data;
  },

  getById: async (id: number): Promise<CorporateTaxSchedule> => {
    const response = await apiClient.get(`/corporate_tax_schedules/${id}`);
    return response.data;
  },

  create: async (data: CorporateTaxScheduleCreateRequest): Promise<CorporateTaxSchedule> => {
    const response = await apiClient.post('/corporate_tax_schedules', {
      corporate_tax_schedule: data
    });
    return response.data;
  },

  update: async (id: number, data: Partial<CorporateTaxScheduleCreateRequest>): Promise<CorporateTaxSchedule> => {
    const response = await apiClient.patch(`/corporate_tax_schedules/${id}`, {
      corporate_tax_schedule: data
    });
    return response.data;
  },

  delete: async (id: number): Promise<void> => {
    await apiClient.delete(`/corporate_tax_schedules/${id}`);
  },

  generate: async (id: number, fiscalYearId: number): Promise<CorporateTaxSchedule> => {
    const response = await apiClient.post(`/corporate_tax_schedules/${id}/generate`, {
      fiscal_year_id: fiscalYearId
    });
    return response.data;
  },

  generateAll: async (fiscalYearId: number): Promise<{
    success: boolean;
    generated: string[];
    failed: string[];
    schedules: CorporateTaxSchedule[];
  }> => {
    const response = await apiClient.post('/corporate_tax_schedules/generate_all', {
      fiscal_year_id: fiscalYearId
    });
    return response.data;
  },

  finalize: async (id: number): Promise<CorporateTaxSchedule> => {
    const response = await apiClient.post(`/corporate_tax_schedules/${id}/finalize`);
    return response.data;
  },

  exportCsv: async (id: number): Promise<Blob> => {
    const response = await apiClient.get(`/corporate_tax_schedules/${id}/export_csv`, {
      responseType: 'blob'
    });
    return response.data;
  },
};
