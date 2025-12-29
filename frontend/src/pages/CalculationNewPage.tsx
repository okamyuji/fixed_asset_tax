import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';
import { useNavigate } from 'react-router-dom';
import { z } from 'zod';
import { useCalculations } from '../hooks/useCalculations';
import type { CalculationRunCreateRequest } from '../types';

const calculationSchema = z.object({
    municipality_id: z.number().min(1, '市区町村を選択してください'),
    fiscal_year_id: z.number().min(1, '年度を選択してください'),
});

type CalculationFormData = z.infer<typeof calculationSchema>;

export const CalculationNewPage = () => {
    const navigate = useNavigate();
    const { createCalculationRun, isCreating } = useCalculations();

    const {
        register,
        handleSubmit,
        formState: { errors },
    } = useForm<CalculationFormData>({
        resolver: zodResolver(calculationSchema),
    });

    const onSubmit = async (data: CalculationRunCreateRequest) => {
        try {
            await createCalculationRun(data);
            navigate('/calculations');
        } catch (error) {
            console.error('Create error:', error);
            alert('登録に失敗しました');
        }
    };

    const handleCancel = () => {
        navigate('/calculations');
    };

    return (
        <div className="px-4 sm:px-6 lg:px-8">
            <div className="md:flex md:items-center md:justify-between">
                <div className="min-w-0 flex-1">
                    <h2 className="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl sm:tracking-tight">
                        新規税額計算
                    </h2>
                </div>
            </div>
            <div className="mt-8 max-w-3xl">
                <div className="bg-white shadow sm:rounded-lg">
                    <div className="px-4 py-5 sm:p-6">
                        <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
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
                                <label htmlFor="fiscal_year_id" className="block text-sm font-medium text-gray-700">
                                    年度ID <span className="text-red-500">*</span>
                                </label>
                                <input
                                    {...register('fiscal_year_id', { valueAsNumber: true })}
                                    type="number"
                                    id="fiscal_year_id"
                                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                                />
                                {errors.fiscal_year_id && (
                                    <p className="mt-1 text-sm text-red-600">{errors.fiscal_year_id.message}</p>
                                )}
                            </div>

                            <div className="flex justify-end space-x-3">
                                <button
                                    type="button"
                                    onClick={handleCancel}
                                    className="rounded-md border border-gray-300 bg-white py-2 px-4 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
                                >
                                    キャンセル
                                </button>
                                <button
                                    type="submit"
                                    disabled={isCreating}
                                    className="inline-flex justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
                                >
                                    {isCreating ? '作成中...' : '作成'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    );
};
