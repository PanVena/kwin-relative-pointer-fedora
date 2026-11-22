// SPDX-License-Identifier: GPL-2.0-or-later
#include <core/output.h>
#include <effect/effect.h>
#include <effect/effecthandler.h>
#include <input_event.h>
#include <input_event_spy.h>
#include <pointer_input.h>
#include <window.h>
#include <workspace.h>
#include <algorithm>
#include <cmath>
#include <limits>

namespace KWin
{

class RelativePointer : public Effect, public InputEventSpy
{
    Q_OBJECT
public:
    RelativePointer() : previous(input()->pointer()->pos())
    {
        input()->installInputEventSpy(this);
    }

    void pointerMotion(PointerMotionEvent *event) override
    {
        const QPointF start = previous;
        previous = event->position;
        if (event->warp || event->delta.isNull() || input()->pointer()->isConstrained()
            || effects->isScreenLocked()) {
            return;
        }

        if (event->buttons != Qt::NoButton) {
            const auto *window = workspace()->moveResizeWindow();
            if (!window || !window->isInteractiveMove()) {
                return;
            }
        }

        const auto screens = effects->screens();
        QRect source;
        for (auto *screen : screens) {
            const QRect rect = screen->geometry();
            if (rect.contains(QPoint(std::floor(start.x()), std::floor(start.y())))) {
                source = rect;
                break;
            }
        }
        if (source.isEmpty()) {
            return;
        }

        // Evaluate both axes so stacked displays and diagonal motion work too.
        double earliest = std::numeric_limits<double>::infinity();
        double nearest = std::numeric_limits<double>::infinity();
        QPointF target;
        for (bool horizontal : {true, false}) {
            const auto orient = [horizontal](QPointF p) { return horizontal ? p : p.transposed(); };
            const QPointF origin = orient(source.topLeft());
            const QPointF size = orient({double(source.width()), double(source.height())});
            const QPointF local = orient(start) - origin;
            const QPointF delta = orient(event->delta);
            if (delta.x() == 0) {
                continue;
            }
            const bool forward = delta.x() > 0;
            const double boundary = forward ? size.x() : 0;
            const double end = local.x() + delta.x();
            if (forward ? end < boundary : end >= boundary) {
                continue;
            }
            const double time = (boundary - local.x()) / delta.x();
            const double crossing = origin.y() + local.y() + time * delta.y();
            for (auto *screen : screens) {
                const QRect rect = screen->geometry();
                const QPointF dest = orient(rect.topLeft());
                const QPointF span = orient({double(rect.width()), double(rect.height())});
                if (dest.x() + (forward ? 0 : span.x()) != origin.x() + boundary
                    || dest.y() >= origin.y() + size.y() || dest.y() + span.y() <= origin.y()) {
                    continue;
                }
                const double distance = std::abs(crossing - std::clamp(crossing, dest.y(), dest.y() + span.y() - 1));
                if (time > earliest || (time == earliest && distance >= nearest)) {
                    continue;
                }
                earliest = time;
                nearest = distance;
                const double x = (forward ? 0 : span.x()) + end - boundary;
                const double y = std::clamp(local.y() + time * delta.y(), 0., size.y() - 1)
                    * (span.y() - 1) / std::max(1., size.y() - 1) + (1 - time) * delta.y();
                target = orient(dest + QPointF(std::clamp(x, 0., span.x() - 1),
                                                std::clamp(y, 0., span.y() - 1)));
            }
        }
        if (std::isfinite(earliest) && target != event->position) {
            input()->pointer()->warp(target);
        }
    }

private:
    QPointF previous;
};

KWIN_EFFECT_FACTORY_SUPPORTED(RelativePointer, "metadata.json", return input() && input()->pointer();)
}
#include "plugin.moc"
