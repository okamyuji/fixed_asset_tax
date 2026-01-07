import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { calculationsApi } from "../api/calculations";
import { useAuthStore } from "../stores/authStore";
import type { CalculationRunCreateRequest } from "../types";

export const useCalculations = () => {
	const tenantId = useAuthStore((state) => state.tenantId);
	const queryClient = useQueryClient();

	const {
		data: calculationRuns = [],
		isLoading,
		error,
	} = useQuery({
		queryKey: ["calculationRuns", tenantId],
		queryFn: () => calculationsApi.list(tenantId!),
		enabled: !!tenantId,
	});

	const createMutation = useMutation({
		mutationFn: (data: CalculationRunCreateRequest) =>
			calculationsApi.create(data, tenantId!),
		onSuccess: () => {
			queryClient.invalidateQueries({
				queryKey: ["calculationRuns", tenantId],
			});
		},
	});

	const executeMutation = useMutation({
		mutationFn: (id: number) => calculationsApi.execute(id, tenantId!),
		onSuccess: () => {
			queryClient.invalidateQueries({
				queryKey: ["calculationRuns", tenantId],
			});
		},
	});

	return {
		calculationRuns,
		isLoading,
		error,
		createCalculationRun: createMutation.mutateAsync,
		executeCalculationRun: executeMutation.mutateAsync,
		isCreating: createMutation.isPending,
		isExecuting: executeMutation.isPending,
	};
};

export const useCalculationRun = (id: number) => {
	const tenantId = useAuthStore((state) => state.tenantId);

	return useQuery({
		queryKey: ["calculationRun", id, tenantId],
		queryFn: () => calculationsApi.get(id, tenantId!),
		enabled: !!tenantId && !!id,
	});
};

export const useCalculationResults = (runId: number) => {
	const tenantId = useAuthStore((state) => state.tenantId);

	return useQuery({
		queryKey: ["calculationResults", runId, tenantId],
		queryFn: () => calculationsApi.getResults(runId, tenantId!),
		enabled: !!tenantId && !!runId,
	});
};
