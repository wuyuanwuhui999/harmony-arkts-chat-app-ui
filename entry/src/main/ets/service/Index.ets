import api from '../api/index';
import httpRequest from '../utils/HttpUtil';
import * as types from '../type/Index'
import CryptoJS from '@ohos/crypto-js';
/**
 * @description: 根据token获取用户信息
 * @date: 2023-12-1 23:39
 * @author wuwenqiang
 */
export const getUserDataService = (token:string):Promise<types.MyAwesomeData<types.UserDataType>>=> {
  httpRequest.setToken(token);
  return httpRequest.get<types.UserDataType>(api.getUserData);
}

/**
 * @description: 注册
 * @date: 2024-01-21 14:48
 * @author wuwenqiang
 */
export const verifyUserService = (userAccount:string|undefined,email:string|undefined):Promise<types.MyAwesomeData<number>>=>{
  const params: types.VerifyUserParamsType = { userAccount, email };
  return httpRequest.post<number>(api.vertifyUser,params)
};

/**
 * @author: wuwenqiang
 * @description: 更新用户信息
 * @date: 2023-12-28 23:18
 */
export const updateUserDataService = (userData:types.UserDataType):Promise<types.MyAwesomeData<number>> => {
  return httpRequest.put<number>(api.updateUser,userData)
};

/**
 * @description: 登录
 * @date: 2024-01-15 21:32
 * @author wuwenqiang
 */
export const loginService = (userAccount:string,password:string):Promise<types.MyAwesomeData<types.UserDataType>>=> {
  password = CryptoJS.MD5(password).toString(); // 使用md5加密
  const params: types.LoginParamsType = { userAccount, password };
  return httpRequest.post<types.UserDataType>(api.login, params)
}


/**
 * @description: 注册
 * @date: 2024-01-19 23:51
 * @author wuwenqiang
 */
export const registerService = (userData:types.UserDataType):Promise<types.MyAwesomeData<types.UserDataType>> => {
  userData.password = CryptoJS.MD5(userData.password).toString(); // 使用md5加密
  return httpRequest.post<types.UserDataType>(api.register,userData)
};

/**
 * @description: 校验账号和密码是否存在
 * @date: 2024-01-19 23:51
 * @author wuwenqiang
 */
export const vertifyUserService = (userData:types.UserDataType):Promise<types.MyAwesomeData<number>> => {
  return httpRequest.post<number>(api.vertifyUser,userData)
};

/**
 * @description: 找回密码
 * @date: 2025-01-19 22:59
 * @author wuwenqiang
 */
export const sendEmailVertifyCodeService = (email:string):Promise<types.MyAwesomeData<number>> => {
  const params:types.EmailParamsType = {email}
  return httpRequest.post<number>(api.sendEmailVertifyCode,params)
};

export const resetPasswordService = (email:string,password:string,code:string):Promise<types.MyAwesomeData<types.UserDataType>>=>{
  password = CryptoJS.MD5(password).toString();// 使用md5加密
  const params: types.ResetPasswordParamsType = {email,password,code};
  return httpRequest.post<types.UserDataType>(api.resetPassword,params)
};

/**
 * @description: 更新密码
 * @date: 2025-01-28 14:22
 * @author wuwenqiang
 */
export const updatePasswordService = (oldPassword:string,newPassword:string):Promise<types.MyAwesomeData<number>> => {
  oldPassword = CryptoJS.MD5(oldPassword).toString();// 使用md5加密
  newPassword = CryptoJS.MD5(newPassword).toString();// 使用md5加密
  const params: types.UpdatePasswordParamsType = {oldPassword,newPassword};
  return httpRequest.put<number>(api.updatePassword,params)
};

/**
 * @description: 邮箱验证码登录
 * @date: 2025-01-28 14:22
 * @author wuwenqiang
 */
export const loginByEmailService = (email:string,code:string):Promise<types.MyAwesomeData<types.UserDataType>> => {
  const params:types.EmailCodeParamsType = {email,code};
  return httpRequest.post<types.UserDataType>(api.loginByEmail,params)
};

/**
 * @description: 获取聊天对话历史记录
 * @date: 2025-05-16 00:19
 * @author wuwenqiang
 */
export const getChatHistoryService = (tenantId:string,pageNum:number,pageSize:number):Promise<types.MyAwesomeData<Array<types.ChatHistoryType>>> => {
  console.log(`获取历史记录,地址：${api.getChatHistory}?tenantId=${tenantId}&pageNum=${pageNum}&pageSize=${pageSize}`)
  return httpRequest.get<Array<types.ChatHistoryType>>(`${api.getChatHistory}?tenantId=${tenantId}pageNum=${pageNum}&pageSize=${pageSize}`);
}

/**
 * @description: 获取模型列表
 * @date: 2025-05-16 00:19
 * @author wuwenqiang
 */
export const getModelListService = (companyId?: string): Promise<types.MyAwesomeData<Array<types.ChatModelType>>> => {
  const url = companyId ? `${api.getModelList}?companyId=${companyId}` : api.getModelList;
  console.log('[Service] getModelListService 请求URL:', url);
  console.log('[Service] getModelListService 参数 companyId:', companyId);
  return httpRequest.get<Array<types.ChatModelType>>(url);
}

/**
 * @description: 上传文档
 * @date: 2025-06-21 13:48
 * @author wuwenqiang
 */
export const getMyDocumentService = (tenantId:string):Promise<types.MyAwesomeData<Array<types.DocumentType>>> => {
  return httpRequest.get<Array<types.DocumentType>>(`${api.getDocList}?tenantId=${tenantId}`);
}

/**
 * @description: 删除文档
 * @date: 2025-07-12 11:31
 * @author wuwenqiang
 */
export const deleteMyDocumentService = (docId:string):Promise<types.MyAwesomeData<number>> => {
  return httpRequest.delete<number>(`${api.deleteDoc}${docId}`);
}

/**
 * @description: 获取目录列表
 * @date: 2025-07-26 20:21
 * @author wuwenqiang
 */
export const getDirectoryListService = (tenantId:string):Promise<types.MyAwesomeData<types.DirectoryType[]>> => {
  return httpRequest.get<types.DirectoryType[]>(`${api.getDirectoryList}?tenantId=${tenantId}`);
}

/**
 * @description: 创建目录
 * @date: 2025-07-27 12:42
 * @author wuwenqiang
 */
export const createDirectoryService = (directory:types.DirectoryType):Promise<types.MyAwesomeData<types.DirectoryType>> => {
  return httpRequest.post<types.DirectoryType>(api.createDir,directory);
}

/**
 * @description: 获取租户列表
 * @date: 2025-08-10 18:25
 * @author wuwenqiang
 */
export const getTenantListService = (companyId?: string): Promise<types.MyAwesomeData<types.TenantType[]>> => {
  return httpRequest.get<types.TenantType[]>(`${api.getTenantList}?companyId=${companyId}`);
}

/**
 * @description: 获取租户下的所有
 * @date: 2025-08-16 20:14
 * @author wuwenqiang
 */
export const getTenantUserListService = (tenantId:string,pageNum:number,pageSize:number):Promise<types.MyAwesomeData<types.TenantUserType[]>> => {
  return httpRequest.get<types.TenantUserType[]>(`${api.getTenantUserList}?tenantId=${tenantId}&pageNum=${pageNum}&pageSize=${pageSize}`);
}

/**
 * @description: 模糊搜索用户
 * @date: 2025-08-16 20:14
 * @author wuwenqiang
 */
export const searchUserListService = (keyword:string,tenantId:string,pageNum:number,pageSize:number):Promise<types.MyAwesomeData<types.UserWithChecked[]>> => {
  return httpRequest.get<types.UserWithChecked[]>(`${api.searchUsers}?keyword=${keyword}&tenantId=${tenantId}&pageNum=${pageNum}&pageSize=${pageSize}`);
}

/**
 * @description: 添加租户
 * @date: 2025-09-01 22:04
 * @author wuwenqiang
 */
export const addTenantUserService = (tenantId:string,userId:string):Promise<types.MyAwesomeData<types.TenantUserType>> => {
  return httpRequest.post<types.TenantUserType>(`${api.addTenantUser}${tenantId}/${userId}`);
}

// ets/service/Index.ets

/**
 * @description: 设置为管理员
 * @date: 2025-09-01 22:04
 * @author wuwenqiang
 */
export const addAdminService = (tenantId: string, userId: string): Promise<types.MyAwesomeData<types.TenantUserType>> => {
  // 修改：使用路径参数
  return httpRequest.post<types.TenantUserType>(`${api.addAdmin}${tenantId}/${userId}`);
}

/**
 * @description: 取消管理员
 * @date: 2025-09-07 09:05
 * @author wuwenqiang
 */
export const deleteAdminService = (tenantId: string, userId: string): Promise<types.MyAwesomeData<types.TenantUserType>> => {
  // 修改：使用路径参数
  return httpRequest.delete<types.TenantUserType>(`${api.deleteAdmin}${tenantId}/${userId}`);
}

/**
 * @description: 删除租户
 * @date: 2025-09-20 14:33
 * @author wuwenqiang
 */
export const deleteTenantUserService = (tenantId:string,userId:string):Promise<types.MyAwesomeData<boolean>> => {
  return httpRequest.delete<boolean>(`${api.deleteTenantUser}/${tenantId}/${userId}`);
}

/**
 * @description: 获取提示词
 * @date: 2026-04-27
 * @author: wuwenqiang
 */
export const getPromptService = (tenantId: string): Promise<types.MyAwesomeData<types.PromptInterface>> => {
  return httpRequest.get<types.PromptInterface>(`${api.getPrompt}?tenantId=${tenantId}`);
}

/**
 * @description: 更新提示词
 * @date: 2026-04-27
 * @author: wuwenqiang
 */
export const updatePromptService = (promptData: types.PromptInterface): Promise<types.MyAwesomeData<types.PromptInterface>> => {
  return httpRequest.put<types.PromptInterface>(api.updatePrompt, promptData);
}

/**
 * @description: 获取公司列表
 * @date: 2026-06-25
 * @author wuwenqiang
 */
export const getCompanyListService = (): Promise<types.MyAwesomeData<types.CompanyType[]>> => {
  return httpRequest.get<types.CompanyType[]>(api.getCompanyList);
}

// 在文件末尾添加

/**
 * @description: 获取公司用户列表
 * @date: 2026-06-26
 * @author wuwenqiang
 */
export const getCompanyUsersService = (params: types.GetCompanyUsersParams): Promise<types.MyAwesomeData<types.CompanyUserType[]>> => {
  const companyId = params.companyId;
  const pageNum = params.pageNum;
  const pageSize = params.pageSize;
  const keyword = params.keyword;
  let url = `${api.getCompanyUsers}?companyId=${companyId}&pageNum=${pageNum}&pageSize=${pageSize}`;
  if (keyword) {
    url += `&keyword=${encodeURIComponent(keyword)}`;
  }
  return httpRequest.get<types.CompanyUserType[]>(url);
}

/**
 * @description: 移除公司用户
 * @date: 2026-06-26
 * @author wuwenqiang
 */
export const removeCompanyUserService = (userId: string, companyId: string): Promise<types.MyAwesomeData<number>> => {
  return httpRequest.delete<number>(`${api.removeCompanyUser}/${userId}/${companyId}`);
}

/**
 * @description: 搜索用户（带companyId）
 * @date: 2026-06-26
 * @author wuwenqiang
 */
export const searchUsersByCompanyService = (companyId: string, keyword: string, pageNum: number, pageSize: number): Promise<types.MyAwesomeData<types.SearchUserType[]>> => {
  return httpRequest.get<types.SearchUserType[]>(`${api.searchUsers}?companyId=${companyId}&keyword=${encodeURIComponent(keyword)}&pageNum=${pageNum}&pageSize=${pageSize}`);
}

/**
 * @description: 添加公司用户
 * @date: 2026-06-26
 * @author wuwenqiang
 */
export const addCompanyUserService = (params: types.AddCompanyUserParams): Promise<types.MyAwesomeData<number>> => {
  return httpRequest.post<number>(api.addCompanyUser, params);
}

/**
 * @description: 获取部门列表
 * @date: 2026-06-26
 * @author wuwenqiang
 */
export const getDepartmentsService = (companyId: string): Promise<types.MyAwesomeData<types.DepartmentType[]>> => {
  return httpRequest.get<types.DepartmentType[]>(`${api.getDepartments}?companyId=${companyId}`);
}

/**
 * @description: 获取职位列表
 * @date: 2026-06-26
 * @author wuwenqiang
 */
export const getPositionsService = (departmentId: string): Promise<types.MyAwesomeData<types.PositionType[]>> => {
  return httpRequest.get<types.PositionType[]>(`${api.getPositions}?departmentId=${departmentId}`);
}

/**
 * @description: 设为管理员
 * @date: 2026-06-26
 * @author wuwenqiang
 */
export const setAdminService = (userId: string, companyId: string): Promise<types.MyAwesomeData<number>> => {
  const params: types.CompanyAdminParamsType = { userId, companyId };
  return httpRequest.post<number>(api.setAdmin, params);
}

/**
 * @description: 取消管理员
 * @date: 2026-06-26
 * @author wuwenqiang
 */
export const cancelAdminService = (userId: string, companyId: string): Promise<types.MyAwesomeData<number>> => {
  const params: types.CompanyAdminParamsType = { userId, companyId };
  return httpRequest.post<number>(api.cancelAdmin, params);
}