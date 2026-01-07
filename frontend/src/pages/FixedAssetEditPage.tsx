import { useNavigate, useParams } from "react-router-dom";
import { FixedAssetForm } from "../components/FixedAssetForm";
import { useFixedAsset, useFixedAssets } from "../hooks/useFixedAssets";
import type { FixedAssetUpdateRequest } from "../types";

export const FixedAssetEditPage = () => {
	const { id } = useParams<{ id: string }>();
	const navigate = useNavigate();
	const { updateFixedAsset, isUpdating } = useFixedAssets();
	const { data: fixedAsset, isLoading } = useFixedAsset(Number(id));

	const handleSubmit = async (data: FixedAssetUpdateRequest) => {
		try {
			await updateFixedAsset({ id: Number(id), data });
			navigate("/fixed-assets");
		} catch (error) {
			console.error("Update error:", error);
			alert("更新に失敗しました");
		}
	};

	const handleCancel = () => {
		navigate("/fixed-assets");
	};

	if (isLoading) {
		return (
			<div className="flex justify-center items-center h-64">
				<div className="text-gray-600">読み込み中...</div>
			</div>
		);
	}

	if (!fixedAsset) {
		return (
			<div className="flex justify-center items-center h-64">
				<div className="text-gray-600">固定資産が見つかりません</div>
			</div>
		);
	}

	return (
		<div className="px-4 sm:px-6 lg:px-8">
			<div className="md:flex md:items-center md:justify-between">
				<div className="min-w-0 flex-1">
					<h2 className="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl sm:tracking-tight">
						固定資産の編集
					</h2>
				</div>
			</div>
			<div className="mt-8 max-w-3xl">
				<div className="bg-white shadow sm:rounded-lg">
					<div className="px-4 py-5 sm:p-6">
						<FixedAssetForm
							fixedAsset={fixedAsset}
							onSubmit={handleSubmit}
							onCancel={handleCancel}
							isSubmitting={isUpdating}
						/>
					</div>
				</div>
			</div>
		</div>
	);
};
