import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { fixedAssetsApi } from '../api/fixedAssets';
import { useAuthStore } from '../stores/authStore';
import type { FixedAssetCreateRequest, FixedAssetUpdateRequest } from '../types';

export const useFixedAssets = (propertyId?: number) => {
    const tenantId = useAuthStore((state) => state.tenantId);
    const queryClient = useQueryClient();

    const { data: fixedAssets = [], isLoading, error } = useQuery({
        queryKey: ['fixedAssets', tenantId, propertyId],
        queryFn: () => fixedAssetsApi.list(tenantId!, propertyId),
        enabled: !!tenantId,
    });

    const createMutation = useMutation({
        mutationFn: (data: FixedAssetCreateRequest) => fixedAssetsApi.create(data, tenantId!),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['fixedAssets', tenantId] });
        },
    });

    const updateMutation = useMutation({
        mutationFn: ({ id, data }: { id: number; data: FixedAssetUpdateRequest }) =>
            fixedAssetsApi.update(id, data, tenantId!),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['fixedAssets', tenantId] });
        },
    });

    const deleteMutation = useMutation({
        mutationFn: (id: number) => fixedAssetsApi.delete(id, tenantId!),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['fixedAssets', tenantId] });
        },
    });

    return {
        fixedAssets,
        isLoading,
        error,
        createFixedAsset: createMutation.mutateAsync,
        updateFixedAsset: updateMutation.mutateAsync,
        deleteFixedAsset: deleteMutation.mutateAsync,
        isCreating: createMutation.isPending,
        isUpdating: updateMutation.isPending,
        isDeleting: deleteMutation.isPending,
    };
};

export const useFixedAsset = (id: number) => {
    const tenantId = useAuthStore((state) => state.tenantId);

    return useQuery({
        queryKey: ['fixedAsset', id, tenantId],
        queryFn: () => fixedAssetsApi.get(id, tenantId!),
        enabled: !!tenantId && !!id,
    });
};
