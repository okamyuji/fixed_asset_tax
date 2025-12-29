import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { BrowserRouter } from 'react-router-dom';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import * as usePropertiesHook from '../../hooks/useProperties';
import { PropertiesPage } from '../PropertiesPage';

const mockProperties = [
    {
        id: 1,
        tenant_id: 1,
        name: 'テスト資産1',
        property_type: 'land' as const,
        party_id: 1,
        municipality_id: 1,
        address: '東京都渋谷区',
        notes: null,
        created_at: '2025-01-01T00:00:00Z',
        updated_at: '2025-01-01T00:00:00Z',
    },
    {
        id: 2,
        tenant_id: 1,
        name: 'テスト資産2',
        property_type: 'depreciable' as const,
        party_id: 2,
        municipality_id: 1,
        address: '東京都新宿区',
        notes: null,
        created_at: '2025-01-01T00:00:00Z',
        updated_at: '2025-01-01T00:00:00Z',
    },
];

const createWrapper = () => {
    const queryClient = new QueryClient({
        defaultOptions: {
            queries: { retry: false },
            mutations: { retry: false },
        },
    });
    return ({ children }: { children: React.ReactNode }) => (
        <QueryClientProvider client={queryClient}>
            <BrowserRouter>{children}</BrowserRouter>
        </QueryClientProvider>
    );
};

describe('PropertiesPage', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('renders properties list', async () => {
        vi.spyOn(usePropertiesHook, 'useProperties').mockReturnValue({
            properties: mockProperties,
            isLoading: false,
            error: null,
            createProperty: vi.fn(),
            updateProperty: vi.fn(),
            deleteProperty: vi.fn(),
            isCreating: false,
            isUpdating: false,
            isDeleting: false,
        });

        render(<PropertiesPage />, { wrapper: createWrapper() });

        expect(screen.getByText('資産管理')).toBeInTheDocument();
        expect(screen.getByText('テスト資産1')).toBeInTheDocument();
        expect(screen.getByText('テスト資産2')).toBeInTheDocument();
    });

    it('shows loading state', () => {
        vi.spyOn(usePropertiesHook, 'useProperties').mockReturnValue({
            properties: [],
            isLoading: true,
            error: null,
            createProperty: vi.fn(),
            updateProperty: vi.fn(),
            deleteProperty: vi.fn(),
            isCreating: false,
            isUpdating: false,
            isDeleting: false,
        });

        render(<PropertiesPage />, { wrapper: createWrapper() });

        expect(screen.getByText('読み込み中...')).toBeInTheDocument();
    });

    it('shows empty state when no properties', () => {
        vi.spyOn(usePropertiesHook, 'useProperties').mockReturnValue({
            properties: [],
            isLoading: false,
            error: null,
            createProperty: vi.fn(),
            updateProperty: vi.fn(),
            deleteProperty: vi.fn(),
            isCreating: false,
            isUpdating: false,
            isDeleting: false,
        });

        render(<PropertiesPage />, { wrapper: createWrapper() });

        expect(screen.getByText('登録されている資産がありません')).toBeInTheDocument();
    });

    it('calls delete function when delete button clicked', async () => {
        const user = userEvent.setup();
        const mockDelete = vi.fn().mockResolvedValue(undefined);

        vi.spyOn(usePropertiesHook, 'useProperties').mockReturnValue({
            properties: mockProperties,
            isLoading: false,
            error: null,
            createProperty: vi.fn(),
            updateProperty: vi.fn(),
            deleteProperty: mockDelete,
            isCreating: false,
            isUpdating: false,
            isDeleting: false,
        });

        // Mock window.confirm
        vi.spyOn(window, 'confirm').mockReturnValue(true);

        render(<PropertiesPage />, { wrapper: createWrapper() });

        const deleteButtons = screen.getAllByText('削除');
        await user.click(deleteButtons[0]);

        await waitFor(() => {
            expect(mockDelete).toHaveBeenCalledWith(1);
        });
    });
});
