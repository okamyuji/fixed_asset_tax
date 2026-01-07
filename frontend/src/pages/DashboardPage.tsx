import {
	Building2,
	Calculator,
	FileText,
	Package,
	Play,
	Plus,
} from "lucide-react";
import { Link } from "react-router-dom";

export const DashboardPage = () => {
	const stats = [
		{
			name: "登録資産数",
			value: "0",
			icon: Building2,
			href: "/properties",
			color: "from-primary-500 to-primary-600",
		},
		{
			name: "固定資産数",
			value: "0",
			icon: Package,
			href: "/fixed-assets",
			color: "from-accent-500 to-accent-600",
		},
		{
			name: "計算実行回数",
			value: "0",
			icon: Calculator,
			href: "/calculations",
			color: "from-emerald-500 to-emerald-600",
		},
	];

	const quickActions = [
		{
			name: "新規資産登録",
			href: "/properties/new",
			icon: Plus,
			color: "from-primary-500 to-primary-600",
			textColor: "text-primary-700",
			bgColor: "bg-primary-50",
		},
		{
			name: "固定資産登録",
			href: "/fixed-assets/new",
			icon: FileText,
			color: "from-accent-500 to-accent-600",
			textColor: "text-accent-700",
			bgColor: "bg-accent-50",
		},
		{
			name: "税額計算実行",
			href: "/calculations/new",
			icon: Play,
			color: "from-emerald-500 to-emerald-600",
			textColor: "text-emerald-700",
			bgColor: "bg-emerald-50",
		},
	];

	return (
		<div className="space-y-6">
			{/* 統計カード */}
			<div className="grid grid-cols-1 gap-6 sm:grid-cols-3">
				{stats.map((stat) => {
					const Icon = stat.icon;
					return (
						<Link
							key={stat.name}
							to={stat.href}
							className="group bg-white rounded-2xl border border-slate-200 p-6 hover:shadow-soft-lg hover:border-slate-300 transition-all duration-300 animate-slide-up"
						>
							<div className="flex items-center justify-between">
								<div>
									<p className="text-sm font-medium text-slate-600">
										{stat.name}
									</p>
									<p className="mt-2 text-3xl font-bold text-slate-900">
										{stat.value}
									</p>
								</div>
								<div
									className={`w-14 h-14 bg-gradient-to-br ${stat.color} rounded-xl flex items-center justify-center group-hover:scale-110 transition-transform duration-300`}
								>
									<Icon className="w-7 h-7 text-white" />
								</div>
							</div>
						</Link>
					);
				})}
			</div>

			{/* クイックアクション */}
			<div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-soft">
				<h3 className="text-lg font-semibold text-slate-900 mb-4">
					クイックアクション
				</h3>
				<div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
					{quickActions.map((action) => {
						const Icon = action.icon;
						return (
							<Link
								key={action.name}
								to={action.href}
								className={`group ${action.bgColor} rounded-xl p-5 hover:shadow-soft transition-all duration-300 flex items-center justify-between border border-slate-200`}
							>
								<span className={`font-semibold ${action.textColor}`}>
									{action.name}
								</span>
								<div
									className={`w-10 h-10 bg-gradient-to-br ${action.color} rounded-lg flex items-center justify-center group-hover:scale-110 transition-transform duration-300`}
								>
									<Icon className="w-5 h-5 text-white" />
								</div>
							</Link>
						);
					})}
				</div>
			</div>

			{/* 最近のアクティビティ */}
			<div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-soft">
				<h3 className="text-lg font-semibold text-slate-900 mb-4">
					最近のアクティビティ
				</h3>
				<div className="text-center py-12 text-slate-500">
					<div className="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
						<FileText className="w-8 h-8 text-slate-400" />
					</div>
					<p className="font-medium">まだアクティビティがありません</p>
					<p className="text-sm mt-1">資産を登録して計算を実行してみましょう</p>
				</div>
			</div>
		</div>
	);
};
