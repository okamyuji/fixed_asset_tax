import { zodResolver } from "@hookform/resolvers/zod";
import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { assetClassificationsApi } from "../api/assetClassifications";
import type {
  AssetClassificationsResponse,
  FixedAsset,
  FixedAssetCreateRequest,
} from "../types";

const fixedAssetSchema = z.object({
  property_id: z.number().min(1, "資産を選択してください"),
  name: z.string().min(1, "資産名を入力してください"),
  asset_type: z.string().min(1, "資産種別を入力してください"),
  account_item: z.string().min(1, "勘定科目を選択してください"),
  asset_classification: z.enum(["tangible", "intangible", "deferred"], {
    errorMap: () => ({ message: "資産分類を選択してください" }),
  }),
  acquired_on: z.string().min(1, "取得日を入力してください"),
  acquisition_cost: z.number().min(0, "取得価額は0以上で入力してください"),
  business_use_ratio: z.number().min(0).max(1).optional(),
  acquisition_type: z
    .enum(["new", "used", "self_constructed", "gift", "inheritance"])
    .optional(),
  service_start_date: z.string().optional(),
  quantity: z.number().int().min(1).optional(),
  unit: z.string().optional(),
  location: z.string().optional(),
  description: z.string().optional(),
  asset_category: z.string().optional(),
  notes: z.string().optional(),
});

type FixedAssetFormData = z.infer<typeof fixedAssetSchema>;

interface FixedAssetFormProps {
  fixedAsset?: FixedAsset;
  onSubmit: (data: FixedAssetCreateRequest) => Promise<void>;
  onCancel: () => void;
  isSubmitting: boolean;
}

export const FixedAssetForm = ({
  fixedAsset,
  onSubmit,
  onCancel,
  isSubmitting,
}: FixedAssetFormProps) => {
  const [classifications, setClassifications] =
    useState<AssetClassificationsResponse | null>(null);
  const [selectedClassification, setSelectedClassification] =
    useState<string>("tangible");

  const {
    register,
    handleSubmit,
    watch,
    formState: { errors },
  } = useForm<FixedAssetFormData>({
    resolver: zodResolver(fixedAssetSchema),
    defaultValues: fixedAsset
      ? {
          property_id: fixedAsset.property_id,
          name: fixedAsset.name,
          asset_type: fixedAsset.asset_type,
          account_item: fixedAsset.account_item,
          asset_classification: fixedAsset.asset_classification,
          acquired_on: fixedAsset.acquired_on,
          acquisition_cost: fixedAsset.acquisition_cost,
          business_use_ratio: fixedAsset.business_use_ratio,
          acquisition_type: fixedAsset.acquisition_type,
          service_start_date: fixedAsset.service_start_date,
          quantity: fixedAsset.quantity,
          unit: fixedAsset.unit,
          location: fixedAsset.location,
          description: fixedAsset.description,
          asset_category: fixedAsset.asset_category || "",
          notes: fixedAsset.notes || "",
        }
      : {
          asset_classification: "tangible",
          acquisition_type: "new",
          quantity: 1,
          business_use_ratio: 1.0,
        },
  });

  const watchedClassification = watch("asset_classification");
  const watchedAccountItem = watch("account_item");

  useEffect(() => {
    const loadClassifications = async () => {
      try {
        const data = await assetClassificationsApi.getAll();
        setClassifications(data);
      } catch (error) {
        console.error("Failed to load classifications:", error);
      }
    };
    loadClassifications();
  }, []);

  useEffect(() => {
    if (watchedClassification) {
      setSelectedClassification(watchedClassification);
    }
  }, [watchedClassification]);

  useEffect(() => {
    const loadUsefulLife = async () => {
      if (watchedAccountItem && classifications) {
        try {
          const data = await assetClassificationsApi.getUsefulLife(
            watchedAccountItem
          );
          if (data.useful_life_years) {
            // 耐用年数を自動設定（depreciation_policyがある場合）
            console.log("Suggested useful life:", data.useful_life_years);
          }
        } catch (error) {
          console.error("Failed to load useful life:", error);
        }
      }
    };
    loadUsefulLife();
  }, [watchedAccountItem, classifications]);

  const getAccountItemsByClassification = () => {
    if (!classifications) return [];

    switch (selectedClassification) {
      case "tangible":
        return classifications.account_items.tangible;
      case "intangible":
        return classifications.account_items.intangible;
      case "deferred":
        return classifications.account_items.deferred;
      default:
        return [];
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
      <div>
        <label
          htmlFor="property_id"
          className="block text-sm font-medium text-gray-700"
        >
          資産ID <span className="text-red-500">*</span>
        </label>
        <input
          {...register("property_id", { valueAsNumber: true })}
          type="number"
          id="property_id"
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
        />
        {errors.property_id && (
          <p className="mt-1 text-sm text-red-600">
            {errors.property_id.message}
          </p>
        )}
      </div>

      <div>
        <label
          htmlFor="name"
          className="block text-sm font-medium text-gray-700"
        >
          資産名 <span className="text-red-500">*</span>
        </label>
        <input
          {...register("name")}
          type="text"
          id="name"
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
        />
        {errors.name && (
          <p className="mt-1 text-sm text-red-600">{errors.name.message}</p>
        )}
      </div>

      <div>
        <label
          htmlFor="asset_classification"
          className="block text-sm font-medium text-gray-700"
        >
          資産分類 <span className="text-red-500">*</span>
        </label>
        <select
          {...register("asset_classification")}
          id="asset_classification"
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
        >
          {classifications?.asset_classifications.map((cls) => (
            <option key={cls.key} value={cls.key}>
              {cls.name}
            </option>
          ))}
        </select>
        {errors.asset_classification && (
          <p className="mt-1 text-sm text-red-600">
            {errors.asset_classification.message}
          </p>
        )}
      </div>

      <div>
        <label
          htmlFor="account_item"
          className="block text-sm font-medium text-gray-700"
        >
          勘定科目 <span className="text-red-500">*</span>
        </label>
        <select
          {...register("account_item")}
          id="account_item"
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
        >
          <option value="">選択してください</option>
          {getAccountItemsByClassification().map((item) => (
            <option key={item.key} value={item.key}>
              {item.name}{" "}
              {item.useful_life_range &&
                `(耐用年数: ${item.useful_life_range.min}〜${item.useful_life_range.max}年)`}
            </option>
          ))}
        </select>
        {errors.account_item && (
          <p className="mt-1 text-sm text-red-600">
            {errors.account_item.message}
          </p>
        )}
      </div>

      <div>
        <label
          htmlFor="asset_type"
          className="block text-sm font-medium text-gray-700"
        >
          資産種別 <span className="text-red-500">*</span>
        </label>
        <input
          {...register("asset_type")}
          type="text"
          id="asset_type"
          placeholder="例: 機械装置、工具器具備品"
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
        />
        {errors.asset_type && (
          <p className="mt-1 text-sm text-red-600">
            {errors.asset_type.message}
          </p>
        )}
      </div>

      <div>
        <label
          htmlFor="acquired_on"
          className="block text-sm font-medium text-gray-700"
        >
          取得日 <span className="text-red-500">*</span>
        </label>
        <input
          {...register("acquired_on")}
          type="date"
          id="acquired_on"
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
        />
        {errors.acquired_on && (
          <p className="mt-1 text-sm text-red-600">
            {errors.acquired_on.message}
          </p>
        )}
      </div>

      <div>
        <label
          htmlFor="acquisition_cost"
          className="block text-sm font-medium text-gray-700"
        >
          取得価額 <span className="text-red-500">*</span>
        </label>
        <input
          {...register("acquisition_cost", { valueAsNumber: true })}
          type="number"
          id="acquisition_cost"
          min="0"
          step="0.01"
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
        />
        {errors.acquisition_cost && (
          <p className="mt-1 text-sm text-red-600">
            {errors.acquisition_cost.message}
          </p>
        )}
      </div>

      <div>
        <label
          htmlFor="acquisition_type"
          className="block text-sm font-medium text-gray-700"
        >
          取得形態
        </label>
        <select
          {...register("acquisition_type")}
          id="acquisition_type"
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
        >
          {classifications?.acquisition_types.map((type) => (
            <option key={type.key} value={type.key}>
              {type.name}
            </option>
          ))}
        </select>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label
            htmlFor="quantity"
            className="block text-sm font-medium text-gray-700"
          >
            数量
          </label>
          <input
            {...register("quantity", { valueAsNumber: true })}
            type="number"
            id="quantity"
            min="1"
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
        </div>
        <div>
          <label
            htmlFor="unit"
            className="block text-sm font-medium text-gray-700"
          >
            単位
          </label>
          <input
            {...register("unit")}
            type="text"
            id="unit"
            placeholder="例: 台、個"
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
        </div>
      </div>

      <div>
        <label
          htmlFor="service_start_date"
          className="block text-sm font-medium text-gray-700"
        >
          事業供用開始日
        </label>
        <input
          {...register("service_start_date")}
          type="date"
          id="service_start_date"
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
        />
        <p className="mt-1 text-xs text-gray-500">
          未入力の場合は取得日が使用されます
        </p>
      </div>

      <div>
        <label
          htmlFor="business_use_ratio"
          className="block text-sm font-medium text-gray-700"
        >
          事業利用割合（個人事業主の場合必須）
        </label>
        <input
          {...register("business_use_ratio", { valueAsNumber: true })}
          type="number"
          id="business_use_ratio"
          min="0"
          max="1"
          step="0.01"
          placeholder="0.0〜1.0"
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
        />
        <p className="mt-1 text-xs text-gray-500">
          例: 100%事業用 = 1.0、50%事業用 = 0.5
        </p>
        {errors.business_use_ratio && (
          <p className="mt-1 text-sm text-red-600">
            {errors.business_use_ratio.message}
          </p>
        )}
      </div>

      <div>
        <label
          htmlFor="location"
          className="block text-sm font-medium text-gray-700"
        >
          設置場所
        </label>
        <input
          {...register("location")}
          type="text"
          id="location"
          placeholder="例: 本社、工場、店舗"
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
        />
      </div>

      <div>
        <label
          htmlFor="description"
          className="block text-sm font-medium text-gray-700"
        >
          説明
        </label>
        <textarea
          {...register("description")}
          id="description"
          rows={3}
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
        />
      </div>

      <div>
        <label
          htmlFor="notes"
          className="block text-sm font-medium text-gray-700"
        >
          備考
        </label>
        <textarea
          {...register("notes")}
          id="notes"
          rows={3}
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
        />
      </div>

      <div className="flex justify-end space-x-3">
        <button
          type="button"
          onClick={onCancel}
          className="rounded-md border border-gray-300 bg-white py-2 px-4 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
        >
          キャンセル
        </button>
        <button
          type="submit"
          disabled={isSubmitting}
          className="inline-flex justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isSubmitting ? "保存中..." : "保存"}
        </button>
      </div>
    </form>
  );
};
