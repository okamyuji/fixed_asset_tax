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
  account_item: string;
  account_item_name: string;
  asset_classification: 'tangible' | 'intangible' | 'deferred';
  asset_classification_name: string;
  business_use_ratio?: number;
  acquisition_type?: 'new' | 'used' | 'self_constructed' | 'gift' | 'inheritance';
  service_start_date?: string;
  quantity?: number;
  unit?: string;
  location?: string;
  description?: string;
  asset_category?: string | null;
  notes?: string | null;
  created_at: string;
  updated_at: string;
  depreciation_policy?: DepreciationPolicyDetail;
}

export interface FixedAssetCreateRequest {
  property_id: number;
  name: string;
  acquired_on: string;
  acquisition_cost: number;
  asset_type: string;
  account_item: string;
  asset_classification: 'tangible' | 'intangible' | 'deferred';
  business_use_ratio?: number;
  acquisition_type?: 'new' | 'used' | 'self_constructed' | 'gift' | 'inheritance';
  service_start_date?: string;
  quantity?: number;
  unit?: string;
  location?: string;
  description?: string;
  asset_category?: string;
  notes?: string;
  depreciation_policy?: DepreciationPolicyCreateRequest;
}

export interface FixedAssetUpdateRequest {
  property_id?: number;
  name?: string;
  acquired_on?: string;
  acquisition_cost?: number;
  asset_type?: string;
  account_item?: string;
  asset_classification?: 'tangible' | 'intangible' | 'deferred';
  business_use_ratio?: number;
  acquisition_type?: 'new' | 'used' | 'self_constructed' | 'gift' | 'inheritance';
  service_start_date?: string;
  quantity?: number;
  unit?: string;
  location?: string;
  description?: string;
  asset_category?: string;
  notes?: string;
  depreciation_policy?: DepreciationPolicyUpdateRequest;
}

export interface DepreciationPolicy {
  method: 'straight_line' | 'declining_balance' | 'declining_balance_250' | 'declining_balance_200';
  useful_life_years: number;
  residual_rate: number;
  depreciation_type: 'normal' | 'lump_sum' | 'small_value' | 'immediate' | 'special' | 'accelerated';
  special_depreciation_rate?: number;
  first_year_prorated?: boolean;
  registered_method?: string;
  depreciation_start_date?: string;
  memo?: string;
}

export interface DepreciationPolicyDetail extends DepreciationPolicy {
  id: number;
  method_name: string;
  depreciation_type_name: string;
}

export interface DepreciationPolicyCreateRequest {
  method: 'straight_line' | 'declining_balance' | 'declining_balance_250' | 'declining_balance_200';
  useful_life_years: number;
  residual_rate: number;
  depreciation_type?: 'normal' | 'lump_sum' | 'small_value' | 'immediate' | 'special' | 'accelerated';
  special_depreciation_rate?: number;
  first_year_prorated?: boolean;
  registered_method?: string;
  depreciation_start_date?: string;
  memo?: string;
}

export interface DepreciationPolicyUpdateRequest {
  method?: 'straight_line' | 'declining_balance' | 'declining_balance_250' | 'declining_balance_200';
  useful_life_years?: number;
  residual_rate?: number;
  depreciation_type?: 'normal' | 'lump_sum' | 'small_value' | 'immediate' | 'special' | 'accelerated';
  special_depreciation_rate?: number;
  first_year_prorated?: boolean;
  registered_method?: string;
  depreciation_start_date?: string;
  memo?: string;
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

export interface AccountItem {
  key: string;
  name: string;
  code: string;
  useful_life_range?: {
    min: number;
    max: number;
  };
  description: string;
}

export interface AssetClassification {
  key: string;
  name: string;
  code: string;
}

export interface AssetClassificationsResponse {
  asset_classifications: AssetClassification[];
  account_items: {
    tangible: AccountItem[];
    intangible: AccountItem[];
    deferred: AccountItem[];
  };
  depreciation_methods: {
    key: string;
    name: string;
    code: string;
  }[];
  depreciation_types: {
    key: string;
    name: string;
    code: string;
    threshold?: {
      min: number;
      max: number;
    };
  }[];
  acquisition_types: {
    key: string;
    name: string;
    code: string;
  }[];
}

export interface CorporateTaxSchedule {
  id: number;
  fiscal_year_id: number;
  fiscal_year: number;
  schedule_type: 'schedule_16_1' | 'schedule_16_2' | 'schedule_16_6' | 'schedule_16_7';
  schedule_type_name: string;
  data_json: Record<string, unknown>;
  status: 'draft' | 'finalized';
  notes?: string;
  finalized_at?: string;
  created_at: string;
  updated_at: string;
}

export interface CorporateTaxScheduleCreateRequest {
  fiscal_year_id: number;
  schedule_type: 'schedule_16_1' | 'schedule_16_2' | 'schedule_16_6' | 'schedule_16_7';
  data_json?: Record<string, unknown>;
  status?: 'draft' | 'finalized';
  notes?: string;
}
