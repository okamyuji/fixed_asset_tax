import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { propertiesApi } from "../api/properties";
import { useAuthStore } from "../stores/authStore";
import type { PropertyCreateRequest, PropertyUpdateRequest } from "../types";

export const useProperties = () => {
	const tenantId = useAuthStore((state) => state.tenantId);
	const queryClient = useQueryClient();

	const {
		data: properties = [],
		isLoading,
		error,
	} = useQuery({
		queryKey: ["properties", tenantId],
		queryFn: () => propertiesApi.list(tenantId!),
		enabled: !!tenantId,
	});

	const createMutation = useMutation({
		mutationFn: (data: PropertyCreateRequest) =>
			propertiesApi.create(data, tenantId!),
		onSuccess: () => {
			queryClient.invalidateQueries({ queryKey: ["properties", tenantId] });
		},
	});

	const updateMutation = useMutation({
		mutationFn: ({ id, data }: { id: number; data: PropertyUpdateRequest }) =>
			propertiesApi.update(id, data, tenantId!),
		onSuccess: () => {
			queryClient.invalidateQueries({ queryKey: ["properties", tenantId] });
		},
	});

	const deleteMutation = useMutation({
		mutationFn: (id: number) => propertiesApi.delete(id, tenantId!),
		onSuccess: () => {
			queryClient.invalidateQueries({ queryKey: ["properties", tenantId] });
		},
	});

	return {
		properties,
		isLoading,
		error,
		createProperty: createMutation.mutateAsync,
		updateProperty: updateMutation.mutateAsync,
		deleteProperty: deleteMutation.mutateAsync,
		isCreating: createMutation.isPending,
		isUpdating: updateMutation.isPending,
		isDeleting: deleteMutation.isPending,
	};
};

export const useProperty = (id: number) => {
	const tenantId = useAuthStore((state) => state.tenantId);

	return useQuery({
		queryKey: ["property", id, tenantId],
		queryFn: () => propertiesApi.get(id, tenantId!),
		enabled: !!tenantId && !!id,
	});
};
