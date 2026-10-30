# Area Feature API Integration Guide

This document describes how to integrate and consume the **Area** CRUD endpoints from the frontend.

---

## ⚠️ Important Architectural Note: RPC-Style POST Endpoints
The backend uses an **RPC-over-POST convention** for this feature.
- **DO NOT** use standard RESTful methods like `GET /api/areas` or `DELETE /api/areas/:id` (these will return `404 Not Found`).
- **ALL requests MUST use `POST`**, with operation targets in the URL path (e.g., `/list`, `/detail`, `/update`, `/delete`) and parameters sent in the JSON body.

---


## 2. API Response Wrappers

### Success Response
```json
{
  "success": true,
  "message": "Operation message",
  "data": { ... }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error description",
  "errors": null // or an object containing field validation errors
}
```

---

## 3. Endpoints Specification

### 3.1. Create Area
Creates a new area belonging to the logged-in user.

- **Method**: `POST`
- **Path**: `/api/areas` *(alias: `/api/areas/create`)*
- **Body Schema**:
  | Field | Type | Required | Constraints | Description |
  |---|---|---|---|---|
  | `name` | `string` | **Yes** | `min: 1`, `max: 255` | Name of the area |
- **Request Example**:
  ```json
  {
    "name": "Greenhouse A"
  }
  ```
- **Response** (`201 Created`):
  ```json
  {
    "success": true,
    "message": "Area created successfully",
    "data": {
      "id": 1,
      "name": "Greenhouse A"
    }
  }
  ```

---

### 3.2. List Areas
Retrieves all areas created by the logged-in user.

- **Method**: `POST`
- **Path**: `/api/areas/list`
- **Body Schema**: `{}` (Empty JSON object or blank body)
- **Response** (`200 OK`):
  ```json
  {
    "success": true,
    "message": "Areas retrieved successfully",
    "data": [
      {
        "id": 1,
        "name": "Greenhouse A"
      },
      {
        "id": 2,
        "name": "Hydroponic Zone B"
      }
    ]
  }
  ```

---

### 3.3. Get Area Detail
Retrieves a specific area by ID.

- **Method**: `POST`
- **Path**: `/api/areas/detail`
- **Body Schema**:
  | Field | Type | Required | Constraints | Description |
  |---|---|---|---|---|
  | `id` | `number` (int64) | **Yes** | `> 0` | ID of the area |
- **Request Example**:
  ```json
  {
    "id": 1
  }
  ```
- **Response** (`200 OK`):
  ```json
  {
    "success": true,
    "message": "Area detail retrieved successfully",
    "data": {
      "id": 1,
      "name": "Greenhouse A"
    }
  }
  ```
- **Error** (`404 Not Found`): If the area ID does not exist or does not belong to the user:
  ```json
  {
    "success": false,
    "message": "area not found"
  }
  ```

---

### 3.4. Update Area
Updates an existing area's name.

- **Method**: `POST`
- **Path**: `/api/areas/update`
- **Body Schema**:
  | Field | Type | Required | Constraints | Description |
  |---|---|---|---|---|
  | `id` | `number` (int64) | **Yes** | `> 0` | ID of the area |
  | `name` | `string` | **Yes** | `min: 1`, `max: 255` | New name |
- **Request Example**:
  ```json
  {
    "id": 1,
    "name": "Greenhouse A - Sector 2"
  }
  ```
- **Response** (`200 OK`):
  ```json
  {
    "success": true,
    "message": "Area updated successfully",
    "data": {
      "id": 1,
      "name": "Greenhouse A - Sector 2"
    }
  }
  ```

---

### 3.5. Delete Area
Deletes an existing area.

- **Method**: `POST`
- **Path**: `/api/areas/delete`
- **Body Schema**:
  | Field | Type | Required | Constraints | Description |
  |---|---|---|---|---|
  | `id` | `number` (int64) | **Yes** | `> 0` | ID of the area |
- **Request Example**:
  ```json
  {
    "id": 1
  }
  ```
- **Response** (`200 OK`):
  ```json
  {
    "success": true,
    "message": "Area deleted successfully",
    "data": null
  }
  ```

---

## 4. TypeScript Types

You can save this as `src/types/area.ts`:

```typescript
export interface Area {
  id: number;
  name: string;
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}

export interface ApiErrorResponse {
  success: boolean;
  message: string;
  errors?: Record<string, string> | null;
}

export interface CreateAreaRequest {
  name: string;
}

export interface AreaDetailRequest {
  id: number;
}

export interface UpdateAreaRequest {
  id: number;
  name: string;
}

export interface DeleteAreaRequest {
  id: number;
}
```

---

## 5. Ready-to-Use Frontend Client (Axios)

Save this as `src/api/areaApi.ts`:

```typescript
import axios from 'axios';
import {
  Area,
  ApiResponse,
  CreateAreaRequest,
  AreaDetailRequest,
  UpdateAreaRequest,
  DeleteAreaRequest,
} from '../types/area';

const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Attach bearer token dynamically
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('token'); // Or use auth store / cookies
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const areaApi = {
  // Create Area
  create: async (data: CreateAreaRequest): Promise<Area> => {
    const res = await apiClient.post<ApiResponse<Area>>('/areas', data);
    return res.data.data;
  },

  // List Areas
  list: async (): Promise<Area[]> => {
    const res = await apiClient.post<ApiResponse<Area[]>>('/areas/list', {});
    return res.data.data;
  },

  // Get Detail
  getDetail: async (data: AreaDetailRequest): Promise<Area> => {
    const res = await apiClient.post<ApiResponse<Area>>('/areas/detail', data);
    return res.data.data;
  },

  // Update Area
  update: async (data: UpdateAreaRequest): Promise<Area> => {
    const res = await apiClient.post<ApiResponse<Area>>('/areas/update', data);
    return res.data.data;
  },

  // Delete Area
  delete: async (data: DeleteAreaRequest): Promise<void> => {
    await apiClient.post<ApiResponse<null>>('/areas/delete', data);
  },
};
```

---

## 6. React Query (TanStack Query) Example

If you are using `@tanstack/react-query`:

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { areaApi } from './areaApi';
import { CreateAreaRequest, UpdateAreaRequest } from '../types/area';

export const useAreas = () => {
  return useQuery({
    queryKey: ['areas'],
    queryFn: areaApi.list,
  });
};

export const useAreaDetail = (id: number) => {
  return useQuery({
    queryKey: ['areas', id],
    queryFn: () => areaApi.getDetail({ id }),
    enabled: id > 0,
  });
};

export const useCreateArea = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateAreaRequest) => areaApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['areas'] });
    },
  });
};

export const useUpdateArea = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: UpdateAreaRequest) => areaApi.update(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['areas'] });
    },
  });
};

export const useDeleteArea = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => areaApi.delete({ id }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['areas'] });
    },
  });
};
```