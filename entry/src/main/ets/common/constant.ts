import { TenantUserType } from "../type/Index";

// export const HOST:string = 'http://254a2y1767.qicp.vip';// 外网映射地址，一般只有晚上才开机，开机之后才能使用，如需调试请联系
export const HOST: string = 'http://169.254.32.117:4000'; // 内网地址
export const USER_DATA: string = 'USER_DATA';//用户信息
export const TENANT_USER_DATA: string = 'TENANT_USER_DATA';//租户信息
export const DEVICE_INFO: string = 'DEVICE_INFO';// 设备信息
export const FAVORITE_MUSIC: string = 'FAVORITE_MUSIC';// 收藏音乐
export const PAGE_SIZE:number = 20;// 每页数据
export const MAX_PAGE_SIZE:number = 500;// 每页最大数量

export const DEFAULT_TENANT_USER:TenantUserType = {
  id: "", // 主键
  tenantId: '', // 租户id
  tenantName: "私人空间",
  userId: "", // 用户id
  roleType: 0, // 用户角色 (0-普通用户，1-租户管理员，2-超级管理员)
  joinDate: '', // 加入日期
  createBy: "", // 创建时间
  username: '', // 用户名
  avater: '', // 头像
  disabled: 0,// 是否禁用
  email: ''// 邮箱
}