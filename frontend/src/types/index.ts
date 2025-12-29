export interface Tenant {
  id: number;
  name: string;
  plan: string;
}

export interface User {
  id: number;
  email: string;
  name?: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  token: string;
}

export interface RegisterRequest {
  tenant_name: string;
  name: string;
  email: string;
  password: string;
  password_confirmation: string;
}

export interface RegisterResponse {
  token: string;
  tenant_id: string;
}

export interface Property {
  id: number;
  tenant_id: number;
  party_id: number;
  municipality_id: number;
  property_type: 'land' | 'depreciable';
  name: string;
  address?: string | null;
  notes?: string | null;
  created_at: string;
  updated_at: string;
}

export interface PropertyCreateRequest {
  name: string;
  property_type: 'land' | 'depreciable';
  party_id: number;
  municipality_id: number;
  address?: string;
  notes?: string;
}

export interface PropertyUpdateRequest {
  name?: string;
  property_type?: 'land' | 'depreciable';
  party_id?: number;
  municipality_id?: number;
  address?: string;
  notes?: string;
}

export interface FixedAsset {
  id: number;
  tenant_id: number;
  property_id: number;
  name: string;
  acquired_on: string;
  acquisition_cost: number;
  asset_type: string;
  asset_category?: string | null;
  notes?: string | null;
  created_at: string;
  updated_at: string;
}

export interface FixedAssetCreateRequest {
  property_id: number;
  name: string;
  acquired_on: string;
  acquisition_cost: number;
  asset_type: string;
  asset_category?: string;
  notes?: string;
}

export interface FixedAssetUpdateRequest {
  property_id?: number;
  name?: string;
  acquired_on?: string;
  acquisition_cost?: number;
  asset_type?: string;
  asset_category?: string;
  notes?: string;
}

export interface DepreciationPolicy {
  method: 'straight_line' | 'declining_balance';
  useful_life_years: number;
  residual_rate: number;
}

export interface CalculationRun {
  id: number;
  tenant_id: number;
  municipality_id: number;
  fiscal_year_id: number;
  status: 'queued' | 'running' | 'succeeded' | 'failed';
  created_at: string;
  updated_at: string;
}

export interface CalculationRunCreateRequest {
  municipality_id: number;
  fiscal_year_id: number;
}

export interface CalculationResult {
  id: number;
  property_id: number;
  property_name: string;
  tax_amount: number;
  breakdown: {
    assessed_value: number;
    tax_base_value: number;
    tax_rate: number;
    tax_amount: number;
  };
}

export interface Municipality {
  id: number;
  code: string;
  name: string;
}

export interface FiscalYear {
  id: number;
  year: number;
  starts_on: string;
  ends_on: string;
}

export interface Party {
  id: number;
  tenant_id: number;
  type: 'Individual' | 'Corporation';
  display_name: string;
}
