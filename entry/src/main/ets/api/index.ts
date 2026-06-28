export default {
  login: '/service/user/login', //登录
  getUserData: '/service/user/getUserData', // 获取用户信息
  updateUser: '/service/user/updateUser',//更新用户信息
  register: '/service/user/register',//注册
  vertifyUser: '/service/user/vertifyUser',// 校验账号是否存在
  sendEmailVertifyCode: '/service/user/sendEmailVertifyCode',// 找回密码
  resetPassword: '/service/user/resetPassword',// 重置密码
  updateAvater:'/service/user/updateAvater',//更新头像
  updatePassword: '/service/user/updatePassword',//更新密码
  loginByEmail: '/service/user/loginByEmail',//邮箱登录
  chat:"/service/chat/chat",// ai聊天
  getChatHistory: "/service/chat/getChatHistory",// ai聊天
  chatWs: "/service/chat/ws/chat",// ai聊天
  getModelList: "/service/chat/getModelList",// ai聊天
  uploadDoc: "/service/chat/uploadDoc",// 生成向量
  getDocList: "/service/chat/getDocList",// 查询我的文档
  deleteDoc: "/service/chat/deleteDoc/",// 删除我的文档
  getDirectoryList: "/service/chat/getDirectoryList",// 查询目录列表
  createDir: "/service/chat/createDir",// 创建目录
  renameDir: "/service/chat/renameDir",// 重命名目录
  deleteDir: "/service/chat/deleteDir/",// 删除目录
  getTenantList: "/service/tenant/getTenantList",// 获取用户当前的所有租户列表
  getTenantUserList: "/service/tenant/getTenantUserList",// 获取当前租户下的用户列表
  getTenantUser: "/service/tenant/getTenantUser",// 获取当前租户下当前用户角色信息
  addTenantUser:"/service/tenant/addTenantUser/",// 添加用户
  addAdmin: "/service/tenant/addAdmin/",        // 添加管理员（路径参数）
  deleteAdmin: "/service/tenant/deleteAdmin/",  // 取消管理员（路径参数）
  deleteTenantUser: "/service/tenant/deleteTenantUser",// 删除用户
  getPrompt: '/service/prompt/getPrompt', // 获取提示词
  updatePrompt: '/service/prompt/updatePrompt', // 更新提示词
  getCompanyList: '/service/company/getCompanyList', // 获取公司列表

  searchUsers: "/service/company/searchUsers",// 搜索用户
  searchTenantUsers: "/service/tenant/searchTenantUsers",// 搜索用户
  getCompanyUsers: '/service/company/getCompanyUsers',      // 获取公司用户列表
  removeCompanyUser: '/service/company/removeUser',         // 移除公司用户
  addCompanyUser: '/service/company/addUser',              // 添加公司用户
  getDepartments: '/service/company/getDepartments',        // 获取部门列表
  getPositions: '/service/company/getPositions',            // 获取职位列表
  setAdmin: '/service/company/setAdmin',                   // 设为管理员
  cancelAdmin: '/service/company/cancelAdmin',             // 取消管理员
};
