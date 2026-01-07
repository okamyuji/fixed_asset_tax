import { ArrowLeft, TrendingUp } from "lucide-react";
import { Link, useParams } from "react-router-dom";
import {
	useCalculationResults,
	useCalculationRun,
} from "../hooks/useCalculations";

export const CalculationResultsPage = () => {
	const { id } = useParams<{ id: string }>();
	const { data: calculationRun, isLoading: isLoadingRun } = useCalculationRun(
		Number(id),
	);
	const { data: results = [], isLoading: isLoadingResults } =
		useCalculationResults(Number(id));

	if (isLoadingRun || isLoadingResults) {
		return (
			<div className="flex justify-center items-center h-64">
				<div className="text-slate-600">読み込み中...</div>
			</div>
		);
	}

	if (!calculationRun) {
		return (
			<div className="flex justify-center items-center h-64">
				<div className="text-slate-600">計算が見つかりません</div>
			</div>
		);
	}

	const totalTax = results.reduce((sum, result) => sum + result.tax_amount, 0);

	return (
		<div className="space-y-6">
			{/* ヘッダー */}
			<div className="flex items-center justify-between">
				<div>
					<h1 className="text-2xl font-bold text-slate-900">税額計算結果</h1>
					<p className="mt-1 text-sm text-slate-600">
						計算ID: {calculationRun.id} | 市区町村ID:{" "}
						{calculationRun.municipality_id} | 年度ID:{" "}
						{calculationRun.fiscal_year_id}
					</p>
				</div>
				<Link
					to="/calculations"
					className="inline-flex items-center gap-2 px-4 py-2.5 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-xl hover:bg-slate-50 hover:shadow-soft transition-all duration-200"
				>
					<ArrowLeft className="w-4 h-4" />
					一覧に戻る
				</Link>
			</div>

			{/* 合計税額カード */}
			<div className="bg-gradient-to-br from-primary-500 to-primary-600 rounded-2xl p-8 text-white shadow-soft-lg">
				<div className="flex items-center gap-3 mb-2">
					<TrendingUp className="w-6 h-6" />
					<h3 className="text-lg font-semibold">合計税額</h3>
				</div>
				<p className="text-4xl font-bold mt-2">¥{totalTax.toLocaleString()}</p>
				<p className="text-primary-100 mt-1 text-sm">固定資産税の年間合計額</p>
			</div>

			{/* 計算結果テーブル */}
			<div className="bg-white rounded-2xl border border-slate-200 shadow-soft overflow-hidden">
				<div className="overflow-x-auto">
					<table className="min-w-full divide-y divide-slate-200">
						<thead className="bg-slate-50">
							<tr>
								<th
									scope="col"
									className="py-4 pl-6 pr-3 text-left text-sm font-semibold text-slate-900"
								>
									資産名
								</th>
								<th
									scope="col"
									className="px-3 py-4 text-left text-sm font-semibold text-slate-900"
								>
									評価額
								</th>
								<th
									scope="col"
									className="px-3 py-4 text-left text-sm font-semibold text-slate-900"
								>
									課税標準額
								</th>
								<th
									scope="col"
									className="px-3 py-4 text-left text-sm font-semibold text-slate-900"
								>
									税率
								</th>
								<th
									scope="col"
									className="px-3 py-4 pr-6 text-left text-sm font-semibold text-slate-900"
								>
									税額
								</th>
							</tr>
						</thead>
						<tbody className="divide-y divide-slate-200 bg-white">
							{results.length === 0 ? (
								<tr>
									<td
										colSpan={5}
										className="py-12 text-center text-sm text-slate-500"
									>
										計算結果がありません
									</td>
								</tr>
							) : (
								results.map((result) => (
									<tr
										key={result.id}
										className="hover:bg-slate-50 transition-colors duration-150"
									>
										<td className="whitespace-nowrap py-4 pl-6 pr-3 text-sm font-medium text-slate-900">
											{result.property_name}
										</td>
										<td className="whitespace-nowrap px-3 py-4 text-sm text-slate-600">
											¥{result.breakdown.assessed_value.toLocaleString()}
										</td>
										<td className="whitespace-nowrap px-3 py-4 text-sm text-slate-600">
											¥{result.breakdown.tax_base_value.toLocaleString()}
										</td>
										<td className="whitespace-nowrap px-3 py-4 text-sm text-slate-600">
											{(result.breakdown.tax_rate * 100).toFixed(2)}%
										</td>
										<td className="whitespace-nowrap px-3 py-4 pr-6 text-sm font-semibold text-primary-700">
											¥{result.tax_amount.toLocaleString()}
										</td>
									</tr>
								))
							)}
						</tbody>
					</table>
				</div>
			</div>
		</div>
	);
};
