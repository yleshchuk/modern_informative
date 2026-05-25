/*
 A modern and informative window switcher layout for KWin.

 SPDX-FileCopyrightText: 2011 Martin Gräßlin <mgraesslin@kde.org>
 SPDX-FileCopyrightText: 2023 Mélanie Chauvel (ariasuni) <perso@hack-libre.org>

 SPDX-License-Identifier: GPL-2.0-or-later
 */
import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kwin 3.0 as KWin

KWin.TabBoxSwitcher {
    id: tabBox
    currentIndex: compactListView.currentIndex

    readonly property bool opaqueBackground: true
    readonly property int iconSize: Kirigami.Units.iconSizes.huge      // medium=32, large=48, huge=64
    readonly property int fontPixelSize: 18                            // default theme is ~13
    readonly property int maxWidth: 700                                // px; captions longer than this get elided
    readonly property bool showCloseButton: true                       // X button to close the window from the switcher

    /**
    * Returns the caption with adjustments for minimized items.
    * @param caption the original caption
    * @param mimized whether the item is minimized
    * @return Caption adjusted for minimized state
    **/
    function itemCaption(caption, minimized) {
        if (minimized) {
            return "(" + caption + ")";
        }
        return caption;
    }

    TextMetrics {
        id: textMetrics
        property string longestCaption: tabBox.model.longestCaption()
        text: itemCaption(longestCaption, true)
        font.pixelSize: tabBox.fontPixelSize
    }

    onVisibleChanged: {
        if (visible) {
            // Window captions may have change completely
            textMetrics.longestCaption = tabBox.model.longestCaption();
        }
    }
    onModelChanged: {
        textMetrics.longestCaption = tabBox.model.longestCaption();
    }

    PlasmaCore.Dialog {
        id: dialog
        location: PlasmaCore.Types.Floating
        visible: tabBox.visible
        flags: Qt.X11BypassWindowManagerHint
        x: tabBox.screenGeometry.x + tabBox.screenGeometry.width * 0.5 - dialogMainItem.width * 0.5
        y: tabBox.screenGeometry.y + tabBox.screenGeometry.height * 0.5 - dialogMainItem.height * 0.5

        mainItem: Item {
            id: dialogMainItem

            property int closeButtonSlot: tabBox.showCloseButton ? Math.round(tabBox.iconSize * 0.6) + 2 * Kirigami.Units.mediumSpacing : 0
            property int optimalWidth: textMetrics.width + tabBox.iconSize + closeButtonSlot + 2 * Kirigami.Units.smallSpacing + hoverItem.margins.right + hoverItem.margins.left
            property int optimalHeight: compactListView.rowHeight * compactListView.count
            width: Math.min(optimalWidth, tabBox.maxWidth)
            height: Math.min(optimalHeight, tabBox.screenGeometry.height * 0.8)
            focus: true

            // just to get the margin sizes
            KSvg.FrameSvgItem {
                id: hoverItem
                imagePath: "widgets/viewitem"
                prefix: "hover"
                visible: false
            }

            Kirigami.Theme.colorSet: Kirigami.Theme.View
            Kirigami.Theme.inherit: false
            Rectangle {
                anchors.fill: parent
                color: Kirigami.Theme.backgroundColor
                visible: tabBox.opaqueBackground
                z: -1
            }

            ListView {
                id: compactListView

                property int rowHeight: Math.max(tabBox.iconSize, textMetrics.height) + hoverItem.margins.top * 2 + hoverItem.margins.bottom * 2

                anchors.fill: parent
                clip: true

                model: tabBox.model
                delegate: RowLayout {
                    id: row

                    width: compactListView.width
                    height: compactListView.rowHeight
                    opacity: minimized ? 0.6 : 1.0

                    spacing: 2 * Kirigami.Units.mediumSpacing

                    HoverHandler {
                        id: rowHover
                    }

                    Kirigami.Icon {
                        id: iconItem
                        source: model.icon
                        Layout.preferredWidth: tabBox.iconSize
                        Layout.preferredHeight: tabBox.iconSize
                        Layout.leftMargin: hoverItem.margins.left * 2
                        Layout.topMargin: hoverItem.margins.top
                        Layout.bottomMargin: hoverItem.margins.bottom
                    }
                    PlasmaComponents3.Label {
                        id: captionItem
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignBottom
                        text: itemCaption(caption, minimized)
                        textFormat: Text.PlainText  // backported from Plasma 6: https://invent.kde.org/plasma/kdeplasma-addons/-/commit/05f7dc7d02ec47edea543912eb4e75126e229069
                        elide: Text.ElideMiddle
                        font.pixelSize: tabBox.fontPixelSize
                        Layout.fillWidth: true
                        Layout.topMargin: hoverItem.margins.top
                        Layout.bottomMargin: hoverItem.margins.bottom
                    }
                    PlasmaComponents3.Label {
                        id: desktopNameItem
                        text: desktopName
                        elide: Text.ElideMiddle
                        visible: tabBox.allDesktops
                        font.pixelSize: tabBox.fontPixelSize
                        Layout.topMargin: hoverItem.margins.top
                        Layout.bottomMargin: hoverItem.margins.bottom
                    }
                    PlasmaComponents3.ToolButton {
                        id: closeButton
                        readonly property bool slotEnabled: tabBox.showCloseButton
                            && model.closeable
                            && typeof tabBox.model.close !== "undefined"
                        icon.name: "window-close-symbolic"
                        icon.width: Math.round(tabBox.iconSize * 0.5)
                        icon.height: Math.round(tabBox.iconSize * 0.5)
                        display: PlasmaComponents3.AbstractButton.IconOnly
                        flat: true
                        visible: slotEnabled
                        // Hide the icon when not hovered, but keep the slot to preserve the right margin
                        opacity: (rowHover.hovered || closeButton.hovered || index === compactListView.currentIndex) ? 1.0 : 0.0
                        enabled: opacity > 0
                        Layout.preferredWidth: Math.round(tabBox.iconSize * 0.6)
                        Layout.preferredHeight: Math.round(tabBox.iconSize * 0.6)
                        Layout.rightMargin: hoverItem.margins.right * 2
                        Layout.topMargin: hoverItem.margins.top
                        Layout.bottomMargin: hoverItem.margins.bottom
                        onClicked: tabBox.model.close(index)
                    }
                    TapHandler {
                        onSingleTapped: {
                            if (index === compactListView.currentIndex) {
                                compactListView.model.activate(index);
                                return;
                            }
                            compactListView.currentIndex = index;
                        }
                        onDoubleTapped: compactListView.model.activate(index)
                    }
                }
                highlight: KSvg.FrameSvgItem {
                    imagePath: "widgets/viewitem"
                    prefix: "hover"
                    width: compactListView.width
                }
                highlightMoveDuration: 0
                highlightResizeDuration: 0
                boundsBehavior: Flickable.StopAtBounds
                Connections {
                    target: tabBox
                    function onCurrentIndexChanged() {compactListView.currentIndex = tabBox.currentIndex;}
                }
            }
            /*
            * Key navigation on outer item for two reasons:
            * @li we have to emit the change signal
            * @li on multiple invocation it does not work on the list view. Focus seems to be lost.
            **/
            Keys.onPressed: {
                if (event.key == Qt.Key_Up) {
                    compactListView.decrementCurrentIndex();
                } else if (event.key == Qt.Key_Down) {
                    compactListView.incrementCurrentIndex();
                }
            }
        }
    }
}
