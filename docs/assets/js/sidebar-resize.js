// Drag handle on the right edge of the just-the-docs sidebar.
//
// The chosen nav column width is stored in localStorage and applied as the
// --sidebar-width custom property on <html>; the layout rules that use it live
// in _sass/custom/custom.scss, and head_custom.html restores the saved width
// before first paint.  Double-click the handle to go back to the theme default.
(function () {
    "use strict";

    var STORAGE_KEY = "sidebar-width";
    var root = document.documentElement;
    var width = null;

    function rem() {
        return parseFloat(getComputedStyle(root).fontSize) || 16;
    }

    // Keep these bounds in sync with the clamp() in custom.scss.
    function minWidth() {
        return 12 * rem();
    }

    function maxWidth() {
        return Math.max(minWidth(), Math.min(40 * rem(), window.innerWidth - 30 * rem()));
    }

    function clamp(w) {
        return Math.min(Math.max(w, minWidth()), maxWidth());
    }

    // The sidebar is max(W, (100% - 50rem + W) / 2) wide, where W is the nav
    // column width (see custom.scss).  Invert that to find the W that puts the
    // sidebar's right edge at x.
    function widthForEdge(x) {
        return Math.min(x, 2 * x - root.clientWidth + 50 * rem());
    }

    function apply(w, handle) {
        width = clamp(w);
        root.style.setProperty("--sidebar-width", width + "px");
        root.classList.add("sidebar-resized");
        handle.setAttribute("aria-valuenow", Math.round(width));
    }

    function save() {
        try {
            if (width === null) {
                localStorage.removeItem(STORAGE_KEY);
            } else {
                localStorage.setItem(STORAGE_KEY, String(Math.round(width)));
            }
        } catch (e) {
            // storage disabled: the width just won't persist
        }
    }

    function reset(handle, nav) {
        width = null;
        root.style.removeProperty("--sidebar-width");
        root.classList.remove("sidebar-resized");
        handle.setAttribute("aria-valuenow", Math.round(nav.getBoundingClientRect().width));
        save();
    }

    function init() {
        var sideBar = document.querySelector(".side-bar");
        var nav = document.getElementById("site-nav");
        if (!sideBar || !nav) {
            return;
        }

        var handle = document.createElement("div");
        handle.className = "sidebar-resizer";
        handle.tabIndex = 0;
        handle.title = "Drag to resize, double-click to reset";
        handle.setAttribute("role", "separator");
        handle.setAttribute("aria-orientation", "vertical");
        handle.setAttribute("aria-label", "Resize sidebar");
        handle.setAttribute("aria-controls", "site-nav");
        handle.setAttribute("aria-valuemin", Math.round(minWidth()));
        handle.setAttribute("aria-valuemax", Math.round(maxWidth()));
        handle.setAttribute("aria-valuenow", Math.round(nav.getBoundingClientRect().width));
        sideBar.appendChild(handle);

        if (root.classList.contains("sidebar-resized")) {
            width = clamp(parseFloat(root.style.getPropertyValue("--sidebar-width")));
        }

        var dragging = false;
        var offset = 0;

        handle.addEventListener("pointerdown", function (e) {
            if (e.button !== 0) {
                return;
            }
            e.preventDefault();
            dragging = true;
            // Grabbing the handle a few pixels off the edge shouldn't make it jump.
            offset = sideBar.getBoundingClientRect().right - e.clientX;
            handle.setPointerCapture(e.pointerId);
            root.classList.add("sidebar-resizing");
        });

        handle.addEventListener("pointermove", function (e) {
            if (dragging) {
                apply(widthForEdge(e.clientX + offset), handle);
            }
        });

        handle.addEventListener("pointerup", function (e) {
            if (handle.hasPointerCapture(e.pointerId)) {
                handle.releasePointerCapture(e.pointerId);
            }
        });

        handle.addEventListener("lostpointercapture", function () {
            if (dragging) {
                dragging = false;
                root.classList.remove("sidebar-resizing");
                save();
            }
        });

        handle.addEventListener("dblclick", function () {
            reset(handle, nav);
        });

        handle.addEventListener("keydown", function (e) {
            var step = e.shiftKey ? 4 * rem() : rem();
            var current = width === null ? nav.getBoundingClientRect().width : width;
            if (e.key === "ArrowLeft") {
                apply(current - step, handle);
            } else if (e.key === "ArrowRight") {
                apply(current + step, handle);
            } else if (e.key === "Home" || e.key === "Escape") {
                reset(handle, nav);
                return;
            } else {
                return;
            }
            e.preventDefault();
            save();
        });

        window.addEventListener("resize", function () {
            handle.setAttribute("aria-valuemax", Math.round(maxWidth()));
        });
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", init);
    } else {
        init();
    }
})();
