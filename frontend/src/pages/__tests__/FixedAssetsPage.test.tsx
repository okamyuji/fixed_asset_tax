import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { BrowserRouter } from "react-router-dom";
import { beforeEach, describe, expect, it, vi } from "vitest";
import * as useFixedAssetsHook from "../../hooks/useFixedAssets";
import { FixedAssetsPage } from "../FixedAssetsPage";

const mockFixedAssets = [
	{
		id: 1,
		tenant_id: 1,
		property_id: 1,
		name: "テスト固定資産1",
		asset_type: "機械装置",
		acquired_on: "2024-01-01",
		acquisition_cost: 1000000,
		asset_category: null,
		notes: null,
		created_at: "2025-01-01T00:00:00Z",
		updated_at: "2025-01-01T00:00:00Z",
	},
	{
		id: 2,
		tenant_id: 1,
		property_id: 1,
		name: "テスト固定資産2",
		asset_type: "工具器具備品",
		acquired_on: "2024-06-01",
		acquisition_cost: 500000,
		asset_category: null,
		notes: null,
		created_at: "2025-01-01T00:00:00Z",
		updated_at: "2025-01-01T00:00:00Z",
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

describe("FixedAssetsPage", () => {
	beforeEach(() => {
		vi.clearAllMocks();
	});

	it("renders fixed assets list", () => {
		vi.spyOn(useFixedAssetsHook, "useFixedAssets").mockReturnValue({
			fixedAssets: mockFixedAssets,
			isLoading: false,
			error: null,
			createFixedAsset: vi.fn(),
			updateFixedAsset: vi.fn(),
			deleteFixedAsset: vi.fn(),
			isCreating: false,
			isUpdating: false,
			isDeleting: false,
		});

		render(<FixedAssetsPage />, { wrapper: createWrapper() });

		expect(screen.getByText("固定資産管理")).toBeInTheDocument();
		expect(screen.getByText("テスト固定資産1")).toBeInTheDocument();
		expect(screen.getByText("テスト固定資産2")).toBeInTheDocument();
	});

	it("shows loading state", () => {
		vi.spyOn(useFixedAssetsHook, "useFixedAssets").mockReturnValue({
			fixedAssets: [],
			isLoading: true,
			error: null,
			createFixedAsset: vi.fn(),
			updateFixedAsset: vi.fn(),
			deleteFixedAsset: vi.fn(),
			isCreating: false,
			isUpdating: false,
			isDeleting: false,
		});

		render(<FixedAssetsPage />, { wrapper: createWrapper() });

		expect(screen.getByText("読み込み中...")).toBeInTheDocument();
	});

	it("shows empty state when no fixed assets", () => {
		vi.spyOn(useFixedAssetsHook, "useFixedAssets").mockReturnValue({
			fixedAssets: [],
			isLoading: false,
			error: null,
			createFixedAsset: vi.fn(),
			updateFixedAsset: vi.fn(),
			deleteFixedAsset: vi.fn(),
			isCreating: false,
			isUpdating: false,
			isDeleting: false,
		});

		render(<FixedAssetsPage />, { wrapper: createWrapper() });

		expect(
			screen.getByText("登録されている固定資産がありません"),
		).toBeInTheDocument();
	});

	it("calls delete function when delete button clicked", async () => {
		const user = userEvent.setup();
		const mockDelete = vi.fn().mockResolvedValue(undefined);

		vi.spyOn(useFixedAssetsHook, "useFixedAssets").mockReturnValue({
			fixedAssets: mockFixedAssets,
			isLoading: false,
			error: null,
			createFixedAsset: vi.fn(),
			updateFixedAsset: vi.fn(),
			deleteFixedAsset: mockDelete,
			isCreating: false,
			isUpdating: false,
			isDeleting: false,
		});

		vi.spyOn(window, "confirm").mockReturnValue(true);

		render(<FixedAssetsPage />, { wrapper: createWrapper() });

		const deleteButtons = screen.getAllByText("削除");
		await user.click(deleteButtons[0]);

		await waitFor(() => {
			expect(mockDelete).toHaveBeenCalledWith(1);
		});
	});
});
