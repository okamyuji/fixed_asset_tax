import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import type { FixedAsset, FixedAssetCreateRequest } from '../types';

const fixedAssetSchema = z.object({
    property_id: z.number().min(1, '資産を選択してください'),
    name: z.string().min(1, '資産名を入力してください'),
    asset_type: z.string().min(1, '資産種別を入力してください'),
    acquired_on: z.string().min(1, '取得日を入力してください'),
    acquisition_cost: z.number().min(0, '取得価額は0以上で入力してください'),
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

export const FixedAssetForm = ({ fixedAsset, onSubmit, onCancel, isSubmitting }: FixedAssetFormProps) => {
    const {
        register,
        handleSubmit,
        formState: { errors },
    } = useForm<FixedAssetFormData>({
        resolver: zodResolver(fixedAssetSchema),
        defaultValues: fixedAsset ? {
            property_id: fixedAsset.property_id,
            name: fixedAsset.name,
            asset_type: fixedAsset.asset_type,
            acquired_on: fixedAsset.acquired_on,
            acquisition_cost: fixedAsset.acquisition_cost,
            asset_category: fixedAsset.asset_category || '',
            notes: fixedAsset.notes || '',
        } : undefined,
    });

    return (
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
            <div>
                <label htmlFor="property_id" className="block text-sm font-medium text-gray-700">
                    資産ID <span className="text-red-500">*</span>
                </label>
                <input
                    {...register('property_id', { valueAsNumber: true })}
                    type="number"
                    id="property_id"
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
                {errors.property_id && (
                    <p className="mt-1 text-sm text-red-600">{errors.property_id.message}</p>
                )}
            </div>

            <div>
                <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                    資産名 <span className="text-red-500">*</span>
                </label>
                <input
                    {...register('name')}
                    type="text"
                    id="name"
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
                {errors.name && (
                    <p className="mt-1 text-sm text-red-600">{errors.name.message}</p>
                )}
            </div>

            <div>
                <label htmlFor="asset_type" className="block text-sm font-medium text-gray-700">
                    資産種別 <span className="text-red-500">*</span>
                </label>
                <input
                    {...register('asset_type')}
                    type="text"
                    id="asset_type"
                    placeholder="例: 機械装置、工具器具備品"
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
                {errors.asset_type && (
                    <p className="mt-1 text-sm text-red-600">{errors.asset_type.message}</p>
                )}
            </div>

            <div>
                <label htmlFor="acquired_on" className="block text-sm font-medium text-gray-700">
                    取得日 <span className="text-red-500">*</span>
                </label>
                <input
                    {...register('acquired_on')}
                    type="date"
                    id="acquired_on"
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
                {errors.acquired_on && (
                    <p className="mt-1 text-sm text-red-600">{errors.acquired_on.message}</p>
                )}
            </div>

            <div>
                <label htmlFor="acquisition_cost" className="block text-sm font-medium text-gray-700">
                    取得価額 <span className="text-red-500">*</span>
                </label>
                <input
                    {...register('acquisition_cost', { valueAsNumber: true })}
                    type="number"
                    id="acquisition_cost"
                    min="0"
                    step="0.01"
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
                {errors.acquisition_cost && (
                    <p className="mt-1 text-sm text-red-600">{errors.acquisition_cost.message}</p>
                )}
            </div>

            <div>
                <label htmlFor="asset_category" className="block text-sm font-medium text-gray-700">
                    資産カテゴリ
                </label>
                <input
                    {...register('asset_category')}
                    type="text"
                    id="asset_category"
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
            </div>

            <div>
                <label htmlFor="notes" className="block text-sm font-medium text-gray-700">
                    備考
                </label>
                <textarea
                    {...register('notes')}
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
                    {isSubmitting ? '保存中...' : '保存'}
                </button>
            </div>
        </form>
    );
};
