import { useNavigate } from 'react-router-dom';
import { FixedAssetForm } from '../components/FixedAssetForm';
import { useFixedAssets } from '../hooks/useFixedAssets';
import type { FixedAssetCreateRequest } from '../types';

export const FixedAssetNewPage = () => {
    const navigate = useNavigate();
    const { createFixedAsset, isCreating } = useFixedAssets();

    const handleSubmit = async (data: FixedAssetCreateRequest) => {
        try {
            await createFixedAsset(data);
            navigate('/fixed-assets');
        } catch (error) {
            console.error('Create error:', error);
            alert('登録に失敗しました');
        }
    };

    const handleCancel = () => {
        navigate('/fixed-assets');
    };

    return (
        <div className="px-4 sm:px-6 lg:px-8">
            <div className="md:flex md:items-center md:justify-between">
                <div className="min-w-0 flex-1">
                    <h2 className="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl sm:tracking-tight">
                        固定資産の新規登録
                    </h2>
                </div>
            </div>
            <div className="mt-8 max-w-3xl">
                <div className="bg-white shadow sm:rounded-lg">
                    <div className="px-4 py-5 sm:p-6">
                        <FixedAssetForm
                            onSubmit={handleSubmit}
                            onCancel={handleCancel}
                            isSubmitting={isCreating}
                        />
                    </div>
                </div>
            </div>
        </div>
    );
};
