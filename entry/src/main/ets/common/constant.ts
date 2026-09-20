import { TenantUserType, SelectOptionType } from "../type/Index";

export const HOST: string = 'http://192.168.147.154:4000'; // 内网地址
export const USER_DATA: string = 'USER_DATA';//用户信息
export const TENANT_USER_DATA: string = 'TENANT_USER_DATA';//租户信息
export const DEVICE_INFO: string = 'DEVICE_INFO';// 设备信息
export const FAVORITE_MUSIC: string = 'FAVORITE_MUSIC';// 收藏音乐
export const PAGE_SIZE:number = 20;// 每页数据
export const MAX_PAGE_SIZE:number = 500;// 每页最大数量

export const COMPANY_ID: string = 'COMPANY_ID'; // 公司ID
export const COMPANY_DATA: string = 'COMPANY_DATA'; // 公司信息
export const PROMPT_ID: string = 'PROMPT_ID'; // 当前使用的提示词id（ViewModel 全局状态）

// ===== 上传文档的文档设置相关常量 =====
// 文档权限选项：private-私密，tenant-租户内公开，company-公司内公开
export const DOC_PERMISSION_OPTIONS: Array<SelectOptionType> = [
  { value: 'private', label: '私密' },
  { value: 'tenant', label: '租户内公开' },
  { value: 'company', label: '公司内公开' }
];
// 分割模式选项
export const DOC_SPLIT_METHOD_OPTIONS: Array<SelectOptionType> = [
  { value: 'recursive', label: '递归字符分割（推荐）' },
  { value: 'paragraph', label: '按段落分割' },
  { value: 'sentence', label: '按句子分割' },
  { value: 'fixed', label: '固定长度分割' }
];
// 固定长度分割的默认分割大小
export const DEFAULT_CHUNK_SIZE: number = 1000;