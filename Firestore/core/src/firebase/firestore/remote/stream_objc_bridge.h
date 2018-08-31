/*
 * Copyright 2018 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_REMOTE_STREAM_OBJC_BRIDGE_H_
#define FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_REMOTE_STREAM_OBJC_BRIDGE_H_

#if !defined(__OBJC__)
#error "This header only supports Objective-C++"
#endif  // !defined(__OBJC__)

#include <string>

#include "Firestore/core/src/firebase/firestore/model/snapshot_version.h"
#include "Firestore/core/src/firebase/firestore/model/types.h"
#include "Firestore/core/src/firebase/firestore/util/status.h"
#include "grpcpp/support/byte_buffer.h"

#import <Foundation/Foundation.h>
#import "Firestore/Protos/objc/google/firestore/v1beta1/Firestore.pbobjc.h"
#import "Firestore/Source/Core/FSTTypes.h"
#import "Firestore/Source/Local/FSTQueryData.h"
#import "Firestore/Source/Model/FSTMutation.h"
#import "Firestore/Source/Remote/FSTSerializerBeta.h"
#import "Firestore/Source/Remote/FSTWatchChange.h"

namespace firebase {
namespace firestore {
namespace remote {
namespace bridge {

bool IsLoggingEnabled();

/**
 * This file contains operations in `WatchStream` that are still delegated to
 * Objective-C: proto parsing and delegates.
 *
 * The principle is that the C++ implementation can only take Objective-C
 * objects as parameters or return them, but never instantiate them or call any
 * methods on them -- if that is necessary, it's delegated to one of the bridge
 * classes. This allows easily identifying which parts of `WatchStream`still
 * rely on not-yet-ported code.
 */

/**
 * A C++ bridge to `FSTSerializerBeta` that allows creating
 * `GCFSListenRequest`s and parsing `GCFSListenResponse`s.
 */
class WatchStreamSerializer {
 public:
  explicit WatchStreamSerializer(FSTSerializerBeta* serializer)
      : serializer_{serializer} {
  }

  GCFSListenRequest* CreateWatchRequest(FSTQueryData* query) const;
  GCFSListenRequest* CreateUnwatchRequest(model::TargetId target_id) const;
  grpc::ByteBuffer ToByteBuffer(GCFSListenRequest* request) const;

  /**
   * If parsing fails, will return nil and write information on the error to
   * `out_status`. Otherwise, returns the parsed proto and sets `out_status` to
   * ok.
   */
  GCFSListenResponse* ParseResponse(const grpc::ByteBuffer& message,
                                    util::Status* out_status) const;
  FSTWatchChange* ToWatchChange(GCFSListenResponse* proto) const;
  model::SnapshotVersion ToSnapshotVersion(GCFSListenResponse* proto) const;

  /** Creates a pretty-printed description of the proto for debugging. */
  NSString* Describe(GCFSListenRequest* request) const;
  NSString* Describe(GCFSListenResponse* request) const;

 private:
  FSTSerializerBeta* serializer_;
};

/**
 * A C++ bridge that invokes methods on an `FSTWatchStreamDelegate`.
 */
class WatchStreamDelegate {
 public:
  explicit WatchStreamDelegate(id delegate) : delegate_{delegate} {
  }

  void NotifyDelegateOnOpen();
  void NotifyDelegateOnChange(FSTWatchChange* change,
                              const model::SnapshotVersion& snapshot_version);
  void NotifyDelegateOnStreamFinished(const util::Status& status);

 private:
  id delegate_;
};

}  // namespace bridge
}  // namespace remote
}  // namespace firestore
}  // namespace firebase

#endif  // FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_REMOTE_STREAM_OBJC_BRIDGE_H_
