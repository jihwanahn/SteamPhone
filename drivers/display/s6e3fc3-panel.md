# Samsung S6E3FC3 AMOLED Panel Driver Notes

## Panel Specifications
- **Size**: 6.5 inches
- **Resolution**: 1080 x 2400 (FHD+)
- **Refresh Rate**: 60Hz / 120Hz (adaptive)
- **Interface**: MIPI-DSI
- **Color Depth**: 8-bit (16.7M colors)
- **HDR**: HDR10+
- **Technology**: Super AMOLED

## Kernel Driver
The panel uses the `panel-samsung-s6e3fc3` DRM panel driver.

### Required DTS entries (Exynos 990)
```dts
&dsi {
    status = "okay";

    panel@0 {
        compatible = "samsung,s6e3fc3";
        reg = <0>;
        reset-gpios = <&gpg1 2 GPIO_ACTIVE_LOW>;
        vdd3-supply = <&ldo26_reg>;
        vci-supply = <&ldo28_reg>;

        port {
            panel_in: endpoint {
                remote-endpoint = <&dsi_out>;
            };
        };
    };
};
```

### Required DTS entries (Snapdragon 865 / SM8250)
```dts
&mdss_dsi0 {
    status = "okay";

    panel@0 {
        compatible = "samsung,s6e3fc3";
        reg = <0>;
        reset-gpios = <&tlmm 75 GPIO_ACTIVE_LOW>;
        vddio-supply = <&vreg_l14a_1p8>;
        vdd-supply = <&vreg_l11a_3p3>;

        port {
            panel_in: endpoint {
                remote-endpoint = <&mdss_dsi0_out>;
            };
        };
    };
};
```

## Rotation
The panel is physically portrait (1080x2400). For gaming, Gamescope handles
rotation to landscape (2400x1080) via:
```
gamescope -W 1080 -H 2400 --force-orientation left
```
