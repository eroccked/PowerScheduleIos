//
//  SplashScreenView.swift
//  PowerScheduleIos
//
//  Created by Taras Buhra on 29.11.2025.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    
    @State private var bounceOffset: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var rotation: Angle = .zero

    var body: some View {
        if isActive {
            MainView()
        } else {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)

                VStack {
                    Image("BulbIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .offset(y: bounceOffset)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .rotationEffect(rotation)
                }
            }
            .onAppear {
                animateBulb()
            }
        }
    }

    private func animateBulb() {

        withAnimation(.easeOut(duration: 0.3)) {
            bounceOffset = -50
            rotation = Angle(degrees: -10)
        } completion: {
            withAnimation(.easeIn(duration: 0.3)) {
                bounceOffset = 0
                rotation = Angle(degrees: 0)
            } completion: {
                withAnimation(.easeOut(duration: 0.25)) {
                    bounceOffset = -30
                    rotation = Angle(degrees: 10)
                } completion: {
                    withAnimation(.easeIn(duration: 0.25)) {
                        bounceOffset = 0
                        rotation = Angle(degrees: 0)
                    } completion: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            bounceOffset = -15
                            rotation = Angle(degrees: -5)
                        } completion: {
                            withAnimation(.easeIn(duration: 0.2)) {
                                bounceOffset = 0
                                rotation = Angle(degrees: 0)
                                scale = 1.05
                            } completion: {
                                withAnimation(.easeOut(duration: 0.1)) {
                                    scale = 1.0
                                } completion: {
                                    withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                                        opacity = 0
                                    } completion: {
                                        isActive = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}


//struct SplashScreenView_Previews: PreviewProvider {
//    static var previews: some View {
//        SplashScreenView()
//    }
//}
