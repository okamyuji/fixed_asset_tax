import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useFixedAssets } from '../hooks/useFixedAssets';

export const FixedAssetsPage = () => {
    const { fixedAssets, isLoading, deleteFixedAsset, isDeleting } = useFixedAssets();
    const [deletingId, setDeletingId] = useState<number | null>(null);

    const handleDelete = async (id: number) => {
        if (!window.confirm('この固定資産を削除してもよろしいですか？')) {
            return;
        }

        setDeletingId(id);
        try {
            await deleteFixedAsset(id);
        } catch (error) {
            console.error('Delete error:', error);
            alert('削除に失敗しました');
        } finally {
            setDeletingId(null);
        }
    };

    if (isLoading) {
        return (
            <div className="flex justify-center items-center h-64">
                <div className="text-gray-600">読み込み中...</div>
            </div>
        );
    }

    return (
        <div className="px-4 sm:px-6 lg:px-8">
            <div className="sm:flex sm:items-center">
                <div className="sm:flex-auto">
                    <h1 className="text-2xl font-semibold text-gray-900">固定資産管理</h1>
                    <p className="mt-2 text-sm text-gray-700">
                        登録されている固定資産の一覧です。
                    </p>
                </div>
                <div className="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
                    <Link
                        to="/fixed-assets/new"
                        className="inline-flex items-center justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:w-auto"
                    >
                        新規登録
                    </Link>
                </div>
            </div>
            <div className="mt-8 flex flex-col">
                <div className="-my-2 -mx-4 overflow-x-auto sm:-mx-6 lg:-mx-8">
                    <div className="inline-block min-w-full py-2 align-middle md:px-6 lg:px-8">
                        <div className="overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg">
                            <table className="min-w-full divide-y divide-gray-300">
                                <thead className="bg-gray-50">
                                    <tr>
                                        <th scope="col" className="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6">
                                            資産名
                                        </th>
                                        <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                                            種別
                                        </th>
                                        <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                                            取得日
                                        </th>
                                        <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                                            取得価額
                                        </th>
                                        <th scope="col" className="relative py-3.5 pl-3 pr-4 sm:pr-6">
                                            <span className="sr-only">操作</span>
                                        </th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-gray-200 bg-white">
                                    {fixedAssets.length === 0 ? (
                                        <tr>
                                            <td colSpan={5} className="py-8 text-center text-sm text-gray-500">
                                                登録されている固定資産がありません
                                            </td>
                                        </tr>
                                    ) : (
                                        fixedAssets.map((asset) => (
                                            <tr key={asset.id}>
                                                <td className="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-6">
                                                    {asset.name}
                                                </td>
                                                <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                                                    {asset.asset_type}
                                                </td>
                                                <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                                                    {asset.acquired_on}
                                                </td>
                                                <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                                                    ¥{asset.acquisition_cost.toLocaleString()}
                                                </td>
                                                <td className="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
                                                    <Link
                                                        to={`/fixed-assets/${asset.id}/edit`}
                                                        className="text-indigo-600 hover:text-indigo-900 mr-4"
                                                    >
                                                        編集
                                                    </Link>
                                                    <button
                                                        onClick={() => handleDelete(asset.id)}
                                                        disabled={isDeleting && deletingId === asset.id}
                                                        className="text-red-600 hover:text-red-900 disabled:opacity-50"
                                                    >
                                                        {isDeleting && deletingId === asset.id ? '削除中...' : '削除'}
                                                    </button>
                                                </td>
                                            </tr>
                                        ))
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};
