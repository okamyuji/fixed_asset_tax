import { Link } from 'react-router-dom';
import { useCalculations } from '../hooks/useCalculations';

const statusLabels = {
    queued: '待機中',
    running: '実行中',
    succeeded: '成功',
    failed: '失敗',
};

const statusColors = {
    queued: 'bg-gray-100 text-gray-800',
    running: 'bg-blue-100 text-blue-800',
    succeeded: 'bg-green-100 text-green-800',
    failed: 'bg-red-100 text-red-800',
};

export const CalculationsPage = () => {
    const { calculationRuns, isLoading, executeCalculationRun, isExecuting } = useCalculations();

    const handleExecute = async (id: number) => {
        if (!window.confirm('この計算を実行してもよろしいですか？')) {
            return;
        }

        try {
            await executeCalculationRun(id);
            alert('計算を開始しました');
        } catch (error) {
            console.error('Execute error:', error);
            alert('実行に失敗しました');
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
                    <h1 className="text-2xl font-semibold text-gray-900">税額計算</h1>
                    <p className="mt-2 text-sm text-gray-700">
                        税額計算の実行履歴と結果を確認できます。
                    </p>
                </div>
                <div className="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
                    <Link
                        to="/calculations/new"
                        className="inline-flex items-center justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:w-auto"
                    >
                        新規計算
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
                                            ID
                                        </th>
                                        <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                                            市区町村ID
                                        </th>
                                        <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                                            年度ID
                                        </th>
                                        <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                                            ステータス
                                        </th>
                                        <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                                            作成日時
                                        </th>
                                        <th scope="col" className="relative py-3.5 pl-3 pr-4 sm:pr-6">
                                            <span className="sr-only">操作</span>
                                        </th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-gray-200 bg-white">
                                    {calculationRuns.length === 0 ? (
                                        <tr>
                                            <td colSpan={6} className="py-8 text-center text-sm text-gray-500">
                                                計算履歴がありません
                                            </td>
                                        </tr>
                                    ) : (
                                        calculationRuns.map((run) => (
                                            <tr key={run.id}>
                                                <td className="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-6">
                                                    {run.id}
                                                </td>
                                                <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                                                    {run.municipality_id}
                                                </td>
                                                <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                                                    {run.fiscal_year_id}
                                                </td>
                                                <td className="whitespace-nowrap px-3 py-4 text-sm">
                                                    <span className={`inline-flex rounded-full px-2 text-xs font-semibold leading-5 ${statusColors[run.status]}`}>
                                                        {statusLabels[run.status]}
                                                    </span>
                                                </td>
                                                <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                                                    {new Date(run.created_at).toLocaleString('ja-JP')}
                                                </td>
                                                <td className="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
                                                    {run.status === 'queued' && (
                                                        <button
                                                            onClick={() => handleExecute(run.id)}
                                                            disabled={isExecuting}
                                                            className="text-indigo-600 hover:text-indigo-900 mr-4 disabled:opacity-50"
                                                        >
                                                            実行
                                                        </button>
                                                    )}
                                                    {run.status === 'succeeded' && (
                                                        <Link
                                                            to={`/calculations/${run.id}/results`}
                                                            className="text-indigo-600 hover:text-indigo-900"
                                                        >
                                                            結果を見る
                                                        </Link>
                                                    )}
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
