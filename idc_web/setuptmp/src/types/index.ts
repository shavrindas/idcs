// src/types/index.ts
export interface Role {
  role_id: number;
  role_name: string;
  data_type?: string; 
}

export interface ChartGroup {
  group_id: number;
  group_name: string;
  role_ids: number[];
}