import { useNavigate } from "react-router-dom";
import { PropertyForm } from "../components/PropertyForm";
import { useProperties } from "../hooks/useProperties";
import type { PropertyCreateRequest } from "../types";

export const PropertyNewPage = () => {
	const navigate = useNavigate();
	const { createProperty, isCreating } = useProperties();

	const handleSubmit = async (data: PropertyCreateRequest) => {
		try {
			await createProperty(data);
			navigate("/properties");
		} catch (error) {
			console.error("Create error:", error);
			alert("登録に失敗しました");
		}
	};

	const handleCancel = () => {
		navigate("/properties");
	};

	return (
		<div className="px-4 sm:px-6 lg:px-8">
			<div className="md:flex md:items-center md:justify-between">
				<div className="min-w-0 flex-1">
					<h2 className="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl sm:tracking-tight">
						資産の新規登録
					</h2>
				</div>
			</div>
			<div className="mt-8 max-w-3xl">
				<div className="bg-white shadow sm:rounded-lg">
					<div className="px-4 py-5 sm:p-6">
						<PropertyForm
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
