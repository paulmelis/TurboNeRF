#pragma once

#include <functional>
#include <stdint.h>

#include "../render-targets/render-target.cuh"
#include "../services/nerf-manager.cuh"
#include "../utils/render-flags.cuh"
#include "../common.h"
#include "camera.cuh"
#include "render-modifiers.cuh"
#include "nerf-proxy.cuh"

TURBO_NAMESPACE_BEGIN

typedef std::function<void()> OnCancelCallback;
typedef std::function<void()> OnCompleteCallback;
typedef std::function<void(float)> OnProgressCallback;

struct RenderRequest {
private:
    bool _canceled = false;
    OnCompleteCallback _on_complete;
    OnProgressCallback _on_progress;
    OnCancelCallback _on_cancel;
public:
    const Camera camera;
    std::vector<NeRFProxy*> proxies;
    RenderModifiers modifiers;
    RenderTarget* output;
    const RenderFlags flags;

    RenderRequest(
        const Camera camera,
        std::vector<NeRFProxy*> proxies,
        RenderTarget* output,
        const RenderModifiers& modifiers,
        const RenderFlags& flags = RenderFlags::Final,
        OnCompleteCallback on_complete = nullptr,
        OnProgressCallback on_progress = nullptr,
        OnCancelCallback on_cancel = nullptr
    )
        : camera(camera)
        , proxies(proxies)
        , modifiers(modifiers)
        , output(output)
        , flags(flags)
        , _on_complete(on_complete)
        , _on_progress(on_progress)
        , _on_cancel(on_cancel)
    { };
    
    bool is_canceled() const {
        return _canceled;
    }

    void cancel() {
        _canceled = true;
    }

    void on_complete() {
        if (_on_complete) {
            _on_complete();
        }
    }

    void on_progress(float progress) {
        if (_on_progress) {
            _on_progress(progress);
        }
    }

    void on_cancel() {
        if (_on_cancel) {
            _on_cancel();
        }
    }

    std::vector<NeRF*> get_nerfs(const int& device_id) const {
        std::vector<NeRF*> nerfs;
        nerfs.reserve(proxies.size());
        for (auto proxy : proxies) {
            nerfs.push_back(&proxy->nerfs[device_id]);
        }
        return nerfs;
    }
};

TURBO_NAMESPACE_END
