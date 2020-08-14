//
//  PreviewView.swift
//  PERDU
//
//  Created by 임성현 on 2020/08/12.
//  Copyright © 2020 임성현. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewView: UIView {
    // 기존 카메라에서 사진을 찍거나 비디오 녹화를 시작하기 전에 사용자가 카메라의 입력을 볼 수 있도록 해야한다. 세션이 실행될 때마다 카메라의 실시간 비디오 피드를 표시하는 캡처 세션에 AVCaptureVideoPreviewLayer를 연결하면 이러한 미리 보기를 제공할 수 있다.
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { // AVCaptureSession에서 나오는 데이터를 보여주기 위해서 AVCaptureVideoPreviewLayer 필요.
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        layer.connection?.videoOrientation = .portrait
        return layer
    }
    
    // PreviewLayer를 관장하는 세션은 뭘로 할꺼냐.
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    // MARK: UIView
    // UIKit 앱에 미리보기 레이어를 추가
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
