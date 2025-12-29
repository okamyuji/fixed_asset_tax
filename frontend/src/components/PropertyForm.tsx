import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import type { Property, PropertyCreateRequest } from '../types';

const propertySchema = z.object({
    name: z.string().min(1, '資産名を入力してください'),
    property_type: z.enum(['land', 'depreciable'], {
        message: '資産種別を選択してください',
    }),
    party_id: z.number().min(1, '所有者を選択してください'),
    municipality_id: z.number().min(1, '市区町村を選択してください'),
    address: z.string().optional(),
    notes: z.string().optional(),
});

type PropertyFormData = z.infer<typeof propertySchema>;

interface PropertyFormProps {
    property?: Property;
    onSubmit: (data: PropertyCreateRequest) => Promise<void>;
    onCancel: () => void;
    isSubmitting: boolean;
}

export const PropertyForm = ({ property, onSubmit, onCancel, isSubmitting }: PropertyFormProps) => {
    const {
        register,
        handleSubmit,
        formState: { errors },
    } = useForm<PropertyFormData>({
        resolver: zodResolver(propertySchema),
        defaultValues: property ? {
            name: property.name,
            property_type: property.property_type,
            party_id: property.party_id,
            municipality_id: property.municipality_id,
            address: property.address || '',
            notes: property.notes || '',
        } : undefined,
    });

    return (
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
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
                <label htmlFor="property_type" className="block text-sm font-medium text-gray-700">
                    資産種別 <span className="text-red-500">*</span>
                </label>
                <select
                    {...register('property_type')}
                    id="property_type"
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                >
                    <option value="">選択してください</option>
                    <option value="land">土地</option>
                    <option value="depreciable">償却資産</option>
                </select>
                {errors.property_type && (
                    <p className="mt-1 text-sm text-red-600">{errors.property_type.message}</p>
                )}
            </div>

            <div>
                <label htmlFor="party_id" className="block text-sm font-medium text-gray-700">
                    所有者ID <span className="text-red-500">*</span>
                </label>
                <input
                    {...register('party_id', { valueAsNumber: true })}
                    type="number"
                    id="party_id"
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
                {errors.party_id && (
                    <p className="mt-1 text-sm text-red-600">{errors.party_id.message}</p>
                )}
            </div>

            <div>
                <label htmlFor="municipality_id" className="block text-sm font-medium text-gray-700">
                    市区町村ID <span className="text-red-500">*</span>
                </label>
                <input
                    {...register('municipality_id', { valueAsNumber: true })}
                    type="number"
                    id="municipality_id"
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
                {errors.municipality_id && (
                    <p className="mt-1 text-sm text-red-600">{errors.municipality_id.message}</p>
                )}
            </div>

            <div>
                <label htmlFor="address" className="block text-sm font-medium text-gray-700">
                    住所
                </label>
                <input
                    {...register('address')}
                    type="text"
                    id="address"
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
