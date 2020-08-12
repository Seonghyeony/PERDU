//
//  CameraViewController.swift
//  PERDU
//
//  Created by 임성현 on 2020/08/12.
//  Copyright © 2020 임성현. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class CameraViewController: UIViewController {
    // TODO: 초기 설정 1
    // 중요 구성
//    - CaptureSession
//    - AVCaptureDeviceInput
//    - AVCapturePhotoOutput // AVCaptureVideoOutput 도 있다.
//    - Queue // 비디오 관련 프로세싱은 그 해당하는 큐에서 일어날 수 있게
//    - AVCaptureDevice DiscoverySession  // 내 Device에서 카메라를 가져올 때 찾아주거나 도와주는 것들.
    // 추가 구성.
    let captureSession = AVCaptureSession()
    var videoDeviceInput: AVCaptureDeviceInput!
    let photoOutput = AVCapturePhotoOutput()
    
    let sessionQueue = DispatchQueue(label: "session Queue")
    // deviceTypes: 카메라가 2개, 3개 이런 것들.
    // position: 전면인지 후면인지.
    let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera, .builtInTrueDepthCamera], mediaType: .video, position: .unspecified)
    

    @IBOutlet weak var photoLibraryButton: UIButton!        // 포토 라이브러리
    
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var captureButton: UIButton!             // 버튼
    @IBOutlet weak var blurBGView: UIVisualEffectView!
    @IBOutlet weak var switchButton: UIButton!              // 토글 스위치
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // UI 요소들이 메모리에 올라왔을 때 해야하는 것.
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: 초기 설정 2
        
        previewView.session = captureSession    // previewView와 AVCaptureSession 연결
        
        // 여기서 AVCaptureSession 구현.
        sessionQueue.async {
            self.setupSession()     // 세션 구성
            self.startSession()     // 세션 시작
        }
        
        setupUI()   // UI 업데이트
        
    }
    
    func setupUI() {
        
        photoLibraryButton.layer.cornerRadius = 10      // 둥근 사각형
        photoLibraryButton.layer.masksToBounds = true   // 위에서 잘린 부분은 masking 해버린다.
        photoLibraryButton.layer.borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)       // #color liter 테두리 흰색
        photoLibraryButton.layer.borderWidth = 1        // border 굵기
        
        captureButton.layer.cornerRadius = captureButton.bounds.height / 2  // bounds: (0, 0, width, height) height를 가져와서 2로 나누면 동그랗게.
        captureButton.layer.masksToBounds = true
        
        blurBGView.layer.cornerRadius = blurBGView.bounds.height / 2  // bounds: (0, 0, width, height) height를 가져와서 2로 나누면 동그랗게.
        blurBGView.layer.masksToBounds = true
    }
    
    
    @IBAction func switchCamera(sender: Any) {
        // TODO: 카메라는 1개 이상이어야함
        guard videoDeviceDiscoverySession.devices.count > 1 else {
            return
        }
        
        // TODO: 반대 카메라 찾아서 재설정
        // - 반대 카메라 찾고
        // - 새로운 디바이스를 가지고 세션을 업데이트
        // - 카메라 토글 버튼 업데이트
        
        sessionQueue.async {
            let currentVideoDevice = self.videoDeviceInput.device
            let currentPosition = currentVideoDevice.position
            let isFront = currentPosition == .front
            let preferredPosition: AVCaptureDevice.Position = isFront ? .back : .front
            
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice?
            
            newVideoDevice = devices.first(where: { device in
                return preferredPosition == device.position
            })
            
            // update capture session
            
            if let newDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: newDevice)
                    self.captureSession.beginConfiguration()
                    self.captureSession.removeInput(self.videoDeviceInput)
                    
                    // add new device input
                    if self.captureSession.canAddInput(videoDeviceInput) {
                        self.captureSession.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    } else {
                        self.captureSession.addInput(self.videoDeviceInput)
                    }
                    
                    self.captureSession.commitConfiguration()
                    
                    // 카메라 토글 버튼 업데이트
                    // UI 업데이트는 main queue에서 한다.
                    // UI 관련해서는 main에서 해야함.
                    DispatchQueue.main.async {
                        self.updateSwitchCameraIcon(position: preferredPosition)
                    }
                    
                    
                } catch let error {
                    print(" error occured while creating device input: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func updateSwitchCameraIcon(position: AVCaptureDevice.Position) {
        // TODO: Update ICON
        switch position {
        case .front:
            //let image = #imageLiteral(resourceName: "ic_camera_front")
            //switchButton.setImage(image, for: .normal)
            print("front")
        case .back:
            //let image = #imageLiteral(resourceName: "ic_camera_rear")
            //switchButton.setImage(image, for: .normal)
            print("back")
        default:
            break
        }
        
    }
    
    @IBAction func capturePhoto(_ sender: UIButton) {
        // TODO: photoOutput의 capturePhoto 메소드
        // orientation - 사진을 찍었는데 막 돌아가있을 수도 있기 때문.
        // photoOutput
        
        let videoPreviewLayerOrientation = self.previewView.videoPreviewLayer.connection?.videoOrientation
        sessionQueue.async {
            // orientation 설정
            let connection = self.photoOutput.connection(with: .video)
            connection?.videoOrientation = videoPreviewLayerOrientation!
            
            /**
             사진을 찍는다.
             */
            let setting = AVCapturePhotoSettings()
            self.photoOutput.capturePhoto(with: setting, delegate: self)
        }
    }
    
    
    func savePhotoLibrary(image: UIImage) {
        // TODO: capture한 이미지 포토라이브러리에 저장
        
        // 포토라이브러리 권한을 받아온다.
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                // 저장
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }, completionHandler: { (success, error) in
                    DispatchQueue.main.async {
                        print(" --> 이미지 저장 완료했나? \(success)")
                        self.photoLibraryButton.setImage(image, for: .normal)
                    }
                })
            } else {
                // 다시 요청
                print("--> 권한을 받지 못함")
            }
        }
    }
}

extension CameraViewController {
    // MARK: - Setup session and preview
    func setupSession() {
        // TODO: captureSession 구성하기
        // - presetSetting 하기
        // - beginConfiguration
        // - Add Video Input
        // - Add Photo Output
        // - commitConfiguration
        
        // preset을 해야함.
        captureSession.sessionPreset = .photo
        captureSession.beginConfiguration()     // 구성 시작!
        
        /*
        // Add Video Input
        do {
            var defaultVideoDevice: AVCaptureDevice?
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                defaultVideoDevice = frontCameraDevice
            }
            
            guard let camera = defaultVideoDevice else {
                captureSession.commitConfiguration()
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: camera)
            
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                captureSession.commitConfiguration()
                return
            }
        } catch {
            captureSession.commitConfiguration()
            return
        }
        */
        
        
        // camera 디바이스 그 자체다.
        guard let camera = videoDeviceDiscoverySession.devices.first else {
            captureSession.commitConfiguration()
            return
        }
        
        do {
            // 디바이스를 Input으로 연결.
            let videoDeviceInput = try AVCaptureDeviceInput(device: camera)
            
            // addInput을 할 수 있느냐?
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                captureSession.commitConfiguration()
                return
            }
        } catch let error {
            captureSession.commitConfiguration()
            return
        }
        
        
        // Add photo(video 도 있다.) Output
        
        // photoOutput에다가 photo를 어떤 형식, 타입으로 저장할 지.
        photoOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
        
        // output을 captureSession에 연결.
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        } else {
            captureSession.commitConfiguration()
            return
        }
        
        captureSession.commitConfiguration()    // 구성 끝!
        
    }
    
    
    
    func startSession() {
        // TODO: session Start
        
        // 특정 스레드에서 작업.
        sessionQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopSession() {
        // TODO: session Stop
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // TODO: capturePhoto delegate method 구현
        // didFinishProcessingPhoto 에서 photo 데이터가 내려온다.
        
        guard error == nil else {
            return
        }
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        guard let image = UIImage(data: imageData) else {
            return
        }
        
        // 사진 찍은거 라이브러리에 저장.
        self.savePhotoLibrary(image: image)
        
    }
}
