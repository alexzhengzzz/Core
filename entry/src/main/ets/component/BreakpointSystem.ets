import mediaQuery from '@ohos.mediaquery';
import { BreakpointConstants } from '../constants/BreakpointConstants';
import { deviceInfo } from '@kit.BasicServicesKit';

declare interface BreakPointTypeOption<T> {
  sm?: T
  md?: T
  lg?: T
}

/**
 * 媒体查询（mediaquery）
 * 响应式设计的核心
 */
export class BreakPointType<T> {
  options: BreakPointTypeOption<T>

  constructor(option: BreakPointTypeOption<T>) {
    this.options = option
  }

  getValue(currentBreakPoint: string): T {
    return Object(this.options)[currentBreakPoint] as T
  }
}

export class BreakpointSystem {
  private currentBreakpoint: string = '';
  private currentOrientation: string = BreakpointConstants.ORIENTATION_PORTRAIT; // 默认为竖屏
  private isTabletDevice: boolean = false; // 是否为平板设备

  private smListener?: mediaQuery.MediaQueryListener;
  private mdListener?: mediaQuery.MediaQueryListener;
  private lgListener?: mediaQuery.MediaQueryListener;
  private orientationListener?: mediaQuery.MediaQueryListener;

  private updateCurrentBreakpoint(breakpoint: string) {
    // 应用特殊逻辑，考虑设备类型和方向
    breakpoint = this.getEffectiveBreakpoint(breakpoint);

    if (this.currentBreakpoint !== breakpoint) {
      this.currentBreakpoint = breakpoint;
      AppStorage.setOrCreate<string>(BreakpointConstants.CURRENT_BREAKPOINT, this.currentBreakpoint);
      console.info(`断点已更新: ${this.currentBreakpoint}`);
    }
  }

  // 根据当前屏幕尺寸和方向确定有效的断点
  private getEffectiveBreakpoint(breakpoint: string): string {
    // 仅针对平板设备处理特殊情况：如果是平板且处于竖屏状态，返回sm断点（手机样式）
    if (this.isTabletDevice &&
      breakpoint === BreakpointConstants.BREAKPOINT_MD &&
      this.currentOrientation === BreakpointConstants.ORIENTATION_PORTRAIT) {
      return BreakpointConstants.BREAKPOINT_SM;
    }

    return breakpoint;
  }

  private isBreakpointSM = (mediaQueryResult: mediaQuery.MediaQueryResult) => {
    if (mediaQueryResult.matches) {
      this.updateCurrentBreakpoint(BreakpointConstants.BREAKPOINT_SM);
    }
  }

  private isBreakpointMD = (mediaQueryResult: mediaQuery.MediaQueryResult) => {
    if (mediaQueryResult.matches) {
      this.updateCurrentBreakpoint(BreakpointConstants.BREAKPOINT_MD);
    }
  }

  private isBreakpointLG = (mediaQueryResult: mediaQuery.MediaQueryResult) => {
    if (mediaQueryResult.matches) {
      this.updateCurrentBreakpoint(BreakpointConstants.BREAKPOINT_LG);
    }
  }

  // 检测设备方向变化
  private orientationChange = (mediaQueryResult: mediaQuery.MediaQueryResult) => {
    const newOrientation = mediaQueryResult.matches ?
    BreakpointConstants.ORIENTATION_LANDSCAPE :
    BreakpointConstants.ORIENTATION_PORTRAIT;

    if (this.currentOrientation !== newOrientation) {
      this.currentOrientation = newOrientation;
      AppStorage.setOrCreate<string>(BreakpointConstants.CURRENT_ORIENTATION, this.currentOrientation);
      console.info(`设备方向已更新: ${this.currentOrientation}`);

      // 方向改变时，如果当前有断点，重新触发断点的更新
      if (this.currentBreakpoint) {
        this.detectCurrentBreakpoint();
      }
    }
  }

  // 检测当前断点
  private detectCurrentBreakpoint() {
    try {
      if (mediaQuery.matchMediaSync(BreakpointConstants.RANGE_SM).matches) {
        this.updateCurrentBreakpoint(BreakpointConstants.BREAKPOINT_SM);
      } else if (mediaQuery.matchMediaSync(BreakpointConstants.RANGE_MD).matches) {
        this.updateCurrentBreakpoint(BreakpointConstants.BREAKPOINT_MD);
      } else if (mediaQuery.matchMediaSync(BreakpointConstants.RANGE_LG).matches) {
        this.updateCurrentBreakpoint(BreakpointConstants.BREAKPOINT_LG);
      }
    } catch (error) {
      console.error('检测当前断点出错:', error);
    }
  }

  // 检测设备类型
  private detectDeviceType() {
    try {
      // 使用deviceInfo API获取设备类型
      const deviceTypeInfo = deviceInfo.deviceType;
      console.info(`设备类型: ${deviceTypeInfo}`);

      // 判断是否为平板设备
      this.isTabletDevice = deviceTypeInfo === 'tablet';

      // 将设备类型存储到AppStorage，供应用其他部分使用
      AppStorage.setOrCreate<boolean>('isTabletDevice', this.isTabletDevice);
    } catch (error) {
      console.error('检测设备类型失败:', error);
    }
  }

  // 初始化系统
  private initialize() {
    // 1. 检测设备类型
    this.detectDeviceType();

    // 2. 初始化设备方向
    const landscapeQuery = mediaQuery.matchMediaSync('(orientation: landscape)');
    this.orientationChange({ matches: landscapeQuery.matches } as mediaQuery.MediaQueryResult);

    // 3. 检测当前断点
    this.detectCurrentBreakpoint();
  }

  public register() {
    try {
      // 注册断点监听器
      this.smListener = mediaQuery.matchMediaSync(BreakpointConstants.RANGE_SM);
      this.smListener.on('change', this.isBreakpointSM);

      this.mdListener = mediaQuery.matchMediaSync(BreakpointConstants.RANGE_MD);
      this.mdListener.on('change', this.isBreakpointMD);

      this.lgListener = mediaQuery.matchMediaSync(BreakpointConstants.RANGE_LG);
      this.lgListener.on('change', this.isBreakpointLG);

      // 注册方向监听器 (横屏查询)
      this.orientationListener = mediaQuery.matchMediaSync('(orientation: landscape)');
      this.orientationListener.on('change', this.orientationChange);

      // 初始化所有状态
      this.initialize();
    } catch (error) {
      console.error('注册响应式系统监听器失败:', error);
    }
  }

  public unregister() {
    this.smListener?.off('change', this.isBreakpointSM);
    this.mdListener?.off('change', this.isBreakpointMD);
    this.lgListener?.off('change', this.isBreakpointLG);
    this.orientationListener?.off('change', this.orientationChange);
  }
}