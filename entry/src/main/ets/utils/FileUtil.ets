// ets/utils/FileUtil.ets
import { picker } from '@kit.CoreFileKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { UploadFileType } from '../type/Index';
import { getFileContentType } from './common';

// 支持选择的文档后缀：txt、pdf、word
const SUPPORT_FILE_SUFFIX: Array<string> = ['.txt', '.pdf', '.doc', '.docx'];

/**
 * @description: 拉起系统文件选择器选择文档，并把文件拷贝到应用沙箱，方便以 multipart/form-data 方式上传
 * @param {string} cacheDir 应用沙箱缓存目录（页面里传 getContext(this).cacheDir，避免工具方法取不到上下文）
 * @return {Promise<UploadFileType | null>} 选中的文件信息，用户取消选择时返回 null
 * @date: 2026-09-19
 * @author wuwenqiang
 */
export const pickDocumentFile = (cacheDir: string): Promise<UploadFileType | null> => {
  const documentPicker = new picker.DocumentViewPicker();
  const options: picker.DocumentSelectOptions = {
    maxSelectNumber: 1,
    fileSuffixFilters: SUPPORT_FILE_SUFFIX
  };
  return documentPicker.select(options).then((uris: Array<string>) => {
    if (!uris || uris.length === 0) {
      // 用户没有选择文件
      return null;
    }
    const uri = uris[0];
    const fileName = uri.substring(uri.lastIndexOf('/') + 1);
    const filePath = `${cacheDir}/${fileName}`;
    // 选择器返回的是 uri，上传接口需要沙箱中的真实文件路径，所以先拷贝到沙箱
    const srcFile = fs.openSync(uri, fs.OpenMode.READ_ONLY);
    fs.copyFileSync(srcFile.fd, filePath);
    fs.closeSync(srcFile);
    const file: UploadFileType = {
      filePath: filePath,
      fileName: fileName,
      contentType: getFileContentType(fileName)
    };
    return file;
  }).catch((err: BusinessError) => {
    console.error('[FileUtil] 选择文件失败:', JSON.stringify(err));
    return null;
  });
}
