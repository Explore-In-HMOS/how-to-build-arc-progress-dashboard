import { AttributeUpdater, window } from '@kit.ArkUI';

class ScoreLabelUpdater extends AttributeUpdater<TextAttribute, TextInterface> {
  private accentColor: ResourceColor = '#7ADFA1';

  initializeModifier(instance: TextAttribute): void {
    instance.fontSize(28);
    instance.fontWeight(FontWeight.Bold);
    instance.fontColor(this.accentColor);
  }

  onComponentChanged(component: TextAttribute): void {
    component.fontColor(this.accentColor);
  }

  setAccent(color: ResourceColor): void {
    this.accentColor = color;
    const attribute = this.attribute;
    if (attribute) {
      attribute.fontColor(color);
    }
  }
}

@Entry
@Component
struct Index {
  @State score: number = 78;
  @State activeTab: number = 0;
  private recovery: string = 'Stable';
  private readiness: string = 'High';
  @State lastTab: string = 'Dashboard';
  @State lastGesture: string = 'None';
  @State inspectLog: string = 'Waiting for observer...';
  @State benchWindowOpened: boolean = false;

  private scoreUpdater: ScoreLabelUpdater = new ScoreLabelUpdater();

  aboutToAppear(): void {
    const uiContext = this.getUIContext();
    const inspector = uiContext.getUIInspector();
    const observer = uiContext.getUIObserver();

    const componentObserver = inspector.createComponentObserver('arc_dashboard_card');
    componentObserver.on('layout', () => {
      this.inspectLog = 'Dashboard card layout finished.';
    });
    componentObserver.on('draw', () => {
      this.inspectLog = 'Dashboard card draw finished.';
    });

    observer.on('didClick', (_event: ClickEvent) => {
      this.lastGesture = 'Tap observed on wearable surface.';
    });
  }

  async openBenchWindow(): Promise<void> {
    if (this.benchWindowOpened) {
      return;
    }

    try {
      const benchWindow = await window.createWindow({
        name: 'wearableInspectBench',
        windowType: window.WindowType.TYPE_DIALOG,
        ctx: this.getUIContext().getHostContext()
      });

      await benchWindow.showWindow();
      this.benchWindowOpened = true;
      this.inspectLog = 'Inspection bench window opened.';
    } catch (error) {
      this.inspectLog = error instanceof Error ? error.message : 'Failed to open inspection bench window.';
    }
  }

  refreshDashboard(): void {
    this.lastTab = 'Dashboard';
    this.score = (this.score + 3) % 100;
    this.scoreUpdater.setAccent(this.score >= 80 ? '#7ADFA1' : '#F7C948');
  }

  refreshInspect(): void {
    this.lastTab = 'Inspect';
  }

  switchTab(tabIndex: number): void {
    if (this.activeTab === tabIndex) {
      return;
    }

    this.activeTab = tabIndex;
    if (tabIndex === 0) {
      this.refreshDashboard();
    } else {
      this.refreshInspect();
    }
  }

  private compactText(value: string, maxLength: number = 26): string {
    if (value.length <= maxLength) {
      return value;
    }
    return `${value.substring(0, maxLength - 1)}...`;
  }

  @Builder
  MetricCard(title: string, value: string): void {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(8)
        .fontColor('#98A2B3')
        .maxLines(1)
      Text(value)
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .backgroundColor('#182230')
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  StatusRow(label: string, value: string): void {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(8)
        .fontColor('#98A2B3')
        .maxLines(1)
      Text(this.compactText(value, 42))
        .fontSize(11)
        .maxLines(2)
    }
    .width('100%')
    .padding({ left: 8, right: 8, top: 5, bottom: 5 })
    .backgroundColor('#182230')
    .borderRadius(10)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  TabPill(label: string, tabIndex: number): void {
    Text(label)
      .fontSize(10)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.activeTab === tabIndex ? '#D0E8FF' : '#6B7280')
      .padding({ left: 11, right: 11, top: 4, bottom: 4 })
      .backgroundColor(this.activeTab === tabIndex ? '#163A66' : '#0F172A')
      .borderRadius(12)
      .onClick(() => {
        this.switchTab(tabIndex);
      })
  }

  @Builder
  TabsHeader(): void {
    Row({ space: 8 }) {
      this.TabPill('Dash', 0)
      this.TabPill('Inspect', 1)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  DashboardTab(): void {
    Scroll() {
      Column({ space: 8 }) {
        Stack({ alignContent: Alignment.Center }) {
          Progress({
            value: this.score,
            total: 100,
            type: ProgressType.Ring
          })
            .width(106)
            .height(106)
            .color('#7ADFA1')
            .backgroundColor('#1D2939')

          Text(`${this.score}`)
            .attributeModifier(this.scoreUpdater)
        }
        .id('arc_dashboard_card')

        Column({ space: 6 }) {
          this.MetricCard('Recovery', this.recovery)
          this.MetricCard('Readiness', this.readiness)
        }
        .width('100%')

        Button('Bench')
          .width('100%')
          .height(30)
          .fontSize(12)
          .onClick(() => {
            this.openBenchWindow();
          })
      }
      .width('100%')
      .padding({ left: 26, right: 26, top: 10, bottom: 26 })
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  InspectTab(): void {
    Scroll() {
      Column({ space: 5 }) {
        this.StatusRow('Last tab', this.lastTab)
        this.StatusRow('Gesture', this.lastGesture)
        this.StatusRow('Inspect', this.inspectLog)
        this.StatusRow('Bench open', this.benchWindowOpened ? 'Yes' : 'No')
      }
      .width('100%')
      .padding({ bottom: 20 })
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 24, right: 24, top: 6, bottom: 6 })
  }

  build() {
    Column({ space: 6 }) {
      this.TabsHeader()

      if (this.activeTab === 0) {
        this.DashboardTab()
      } else {
        this.InspectTab()
      }
    }
    .width('100%')
    .height('100%')
    .padding({ top: 10, bottom: 10 })
    .clip(true)
  }
}
