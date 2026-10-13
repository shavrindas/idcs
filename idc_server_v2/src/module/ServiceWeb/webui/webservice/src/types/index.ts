// src/types/index.ts
export interface Role {
  role_id: number;
  role_name: string;       
  display_name?: string;    
  short_name?: string;      
  target_value?: string;
  data_type?: string;
}
export interface ChartGroup {
  group_id: number;
  group_name: string;
  role_ids: number[];
}
/** 로그인한 사용자. 로그인 응답과 프로필을 합쳐 App 이 들고 있다. */
export interface SessionUser {
  id: number;
  email: string;
  name: string;
  role: string;
}
