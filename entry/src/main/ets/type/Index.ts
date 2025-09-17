import type { PositionEnum } from '../enum/index';

export interface MyAwesomeData<T> {
  data: T;
  token: string;
  status:string;
  msg:string;
  total:number
}

export interface DeviceType{
  musicId:number|null
  version:string,
  platform:string,
  device:string
}

export interface UpdatePasswordParamsType {
  oldPassword: string;
  newPassword: string;
}

export interface ResetPasswordParamsType {
  email: string;
  password: string;
  code: string;
}

export interface EmailParamsType {
  email: string;
}

export interface EmailCodeParamsType {
  email: string;
  code: string;
}

// 添加以下接口
export interface LoginParamsType {
  userAccount: string;
  password: string;
}

export interface VerifyUserParamsType {
  userAccount?: string;
  email?: string;
}

export type UserDataType = {
  id?: string;
  userAccount:     string;
  createDate?: string;
  updateDate?: string;
  username:   string;
  telephone:  string;
  email:      string;
  avater?:     string;
  birthday:   string;
  sex:        string;
  role?:       string;
  password:   string;
  sign:       string;
  region:     string;
  disabled?:   number;
  permission?: number;
}

// 主体数据结构，键是时间前缀，值是该时间前缀下的消息组
export type ChatStructure = {
  timeAgo:string,
  list:Array<Array<ChatHistoryType>>
}

export type ChatModelType = {
  id:number,
  modelName:string,
  updateTime:string,
  createTime:string
}
export interface ChatParamsType {
  modelName:string,
  token: string, // 替换为实际用户ID
  chatId:string, // 替换为实际聊天ID
  prompt: string,// 提示词
  type:string,//查询的类型
  showThink:boolean,// 是否显示思考内容
  language:string//语言
}

// 聊天气泡
export type ChatType = {
  text?:string,
  position:PositionEnum,
  thinkContent?:string,
  responseContent?:string,
  start?:boolean
}
// 聊天气泡
export type ChatHistoryType = {
  id: number;          // 主键
  modelName:string,      // 模型id
  userId: string;      // 用户id
  files?: string;       // 文件（
  chatId: string;      // 会话id
  prompt: string;      // 提示词
  content: string;     // 内容
  createTime: string;  // 创建时间
  thinkContent?:string,// 思考内容
  responseContent?:string,// 正文内容
  timeAgo:string;// xx分钟、小时、天、月前
}

export type GroupedByChatIdType = {
  [chatId: string]: ChatHistoryType[];
}

export type GroupedByTimeAgoType = {
  [timeAgo: string]:  ChatHistoryType[][];
}

export type FileType = 'txt' | 'pdf';

export interface UploadFile {
  path: string;
  name: string;
  size: number;
  type: string;
}

export interface UploadResponse {
  code: number;
  message: string;
  data?: any;
  status:string;
}

export interface PayloadType {
  modelName: string;
  token: string; // 替换为实际用户ID
  chatId:string; // 替换为实际聊天ID
  tenantId:string;
  type: string;
  prompt: string;
  showThink:boolean;
  directoryId?:string;
  language:string;
};

export interface DocumentType {
  id: string;// 文档id
  name: string; // 文档名称
  ext:string; // 文档格式
  userId: string;// 用户id
  createTime: string;//创建时间
  updateTime: string// 更新时间
  directoryId:string// 目录id
  directoryName:string;// 目录名称
};

export interface OptionType {
  text:string,
  value:string | number
}

export interface AdminParamsType {
  tenantId:string,
  userId:string
}

// 文档的目录
export interface DirectoryInterce {
  id?:string;// 目录id
  userId?:string;// 用户id
  directory:string;// 目录名称
  tenantId: string;// 租户id
  createTime?:string;// 创建时间
  updateTime?:string;// 更新时间
}

// 租户
export interface TenantUserType {
  id: string; // 主键
  tenantId: string; // 租户id
  tenantName: string;
  userId: string; // 用户id
  roleType: number; // 用户角色 (0-普通用户，1-租户管理员，2-超级管理员)
  joinDate: string; // 加入日期
  createBy: string; // 创建时间
  username: string; // 用户名
  avater?: string; // 头像
  disabled: number;// 是否禁用
  email: string;// 邮箱
}

/** 租户状态枚举 */
export enum TenantStatus {
  DISABLED = 0,// 禁用
  ENABLED = 1// 启用
}

export interface TenantType {
  id: string;// 租户ID（主键）
  name: string;// 租户名称
  code: string;// 租户编码（唯一）
  description?: string | null;// 租户描述（可选）
  status: TenantStatus;// 租户状态
  create_date?: Date;// 创建时间
  update_date?: Date | null;// 更新时间（可选）
  created_by: string;// 创建人ID
  updated_by?: string | null;// 更新人ID（可选）
}

export interface AppStoreStateType {
  userData: UserDataType;
  token: string;
  platform: string;
  device: string;
  version: string;
  tenantUser: TenantUserType;
}

// 或者使用接口继承的方式
export interface UserWithChecked extends UserDataType {
  checked: number;
}