(function(global) {
  const F = (frame, from, delta) => (
    frame - FRAME_FOR_BEAN(from)) / (FRAME_FOR_BEAN(from + delta) - FRAME_FOR_BEAN(from)
  );

  class canvasLayer0 extends NIN.THREENode {
    constructor(id) {
      super(id, {
        outputs: {
          render: new NIN.TextureOutput()
        }
      });

      this.canvas = document.createElement('canvas');
      this.ctx = this.canvas.getContext('2d');

      this.width = 1024;
      this.height = 1024;

      this.canvas.width = this.width;
      this.canvas.height = this.height;

      this.output = new THREE.VideoTexture(this.canvas);
      this.output.minFilter = THREE.LinearFilter;
      this.output.magFilter = THREE.LinearFilter;

      this.colors = [
        '#F7CC18',
        '#F78B1E',
        '#F72871',
        '#EA21F7',
        '#881DF7',
        '#EA21F7',
        '#F72871',
        '#F78B1E',
      ];
    }

    update(frame) {
      super.update(frame);

      this.ctx.save();
      this.ctx.translate(this.halfWidth, this.halfHeight);
/*
      const t = frame / 60;
      const scalingFactor = 2.42;
      const rectWidth = 36;

      const explodeStartBean = 316;
      const explodeDuration = 8;
      const explodeProgress = F(frame, explodeStartBean, explodeDuration);
      if (BEAN < explodeStartBean) {
        const color = this.colors[(0 | (BEAN / 4) + 5) % this.colors.length];
        this.ctx.fillStyle = BEAN % 4 < 2 ? color : 'black';
        this.ctx.fillRect(- rectWidth / 2, - rectWidth / 2, rectWidth, rectWidth);
      } else if (BEAN < explodeStartBean + explodeDuration) {
        this.ctx.save();
        this.ctx.globalAlpha = 0.07 - explodeProgress * 0.07;
        this.ctx.fillStyle = this.colors[4];
        this.ctx.fillRect(- rectWidth / 2, - rectWidth / 2, rectWidth, rectWidth);
        this.ctx.restore();
      } else {
        this.ctx.save();
        const color = this.colors[(0 | (BEAN / 4) + 3) % this.colors.length];
        this.ctx.globalAlpha = 0.05;
        this.ctx.fillStyle = color;
        this.ctx.fillRect(- rectWidth / 2, - rectWidth / 2, rectWidth, rectWidth);
        this.ctx.restore();
      }

      if (BEAN >= explodeStartBean && BEAN < explodeStartBean + explodeDuration) {
        this.ctx.fillStyle = `rgba(255, 255, 255, ${explodeProgress})`;
        const particleSize = (0.03 + 0.05 * explodeProgress) * 24;
        const radius = 40 * (0.5 + Math.pow(1.77 * explodeProgress, 2));

        for (let i = 0; i < explodeProgress * 40; i++) {
          this.ctx.fillRect(
            radius * (-0.5 + Math.random()) - particleSize / 2,
            radius * (-0.5 + Math.random()) - particleSize / 2,
            particleSize,
            particleSize
          );
        }
      }

      if (explodeProgress <= 1) {
        this.ctx.rotate(
          smoothstep(
            0.005 * Math.sin(1.2 * t),
            0,
            explodeProgress
          )
        );
      } else {
        this.ctx.rotate(
          smoothstep(
            0,
            0.009 * Math.sin(1.2 * t),
            explodeProgress - 1
          )
        );
      }

      if (BEAN < 348) {
        this.ctx.drawImage(
          this.canvas,
          -this.halfWidth - scalingFactor * 2,
          -this.halfHeight - scalingFactor,
          this.width + 4 * scalingFactor,
          this.height + 2 * scalingFactor
        );
      } else {
        this.ctx.fillStyle = '#000000';
        this.ctx.fillRect(
          -this.halfWidth,
          -1.05 * this.halfHeight,
          0.836 * this.halfWidth,
          easeOut(0, this.height * 1.1, F(frame, 350, 2))
        );
        this.ctx.fillRect(
          39,
          -this.halfHeight,
          this.halfWidth,
          easeOut(0, this.height * 1.1, F(frame, 352, 2))
        );
      }
*/
      var canvas_size = 1024;
      var size = 800;
      var width_small = 15;
      var width_large = 50;


      this.ctx.fillStyle = '#6c79ae';
      this.ctx.fillRect((canvas_size - size) / 2,
                        (canvas_size - size) / 2, 
                        size,
                        size);
      this.ctx.clearRect((canvas_size - size) / 2 + width_small,
                          (canvas_size - size) / 2 + width_small,
                          size - 2 * width_small,
                          size - 2 * width_small);

      this.ctx.fillRect((canvas_size - size) / 2 + 2 * width_small,
                        (canvas_size - size) / 2 + 2 * width_small,
                        size - 4 * width_small,
                        size - 4 * width_small);
      this.ctx.clearRect((canvas_size - size) / 2 + width_small + width_large,
                          (canvas_size - size) / 2 + width_small + width_large,
                          size - 2 * width_small - 2 * width_large,
                          size - 2 * width_small - 2 * width_large);

      this.ctx.fillRect((canvas_size - size) / 2 + 2 * width_small + width_large,
                        (canvas_size - size) / 2 + 2 * width_small + width_large,
                        size - 4 * width_small - 2 * width_large,
                        size - 4 * width_small - 2 * width_large);
      this.ctx.clearRect((canvas_size - size) / 2 + 3 * width_small + width_large,
                          (canvas_size - size) / 2 + 3 * width_small + width_large,
                          size - 6 * width_small - 2 * width_large,
                          size - 6 * width_small - 2 * width_large);

      /*this.ctx.fillRect(130, 130, 740, 740);
      this.ctx.clearRect(150, 150, 700, 700);


      this.ctx.fillRect(100, 100, 800, 800);
      this.ctx.clearRect(110, 110, 780, 780);*/



      this.ctx.restore();
    }

    render() {
      this.output.needsUpdate = true;
      this.outputs.render.setValue(this.output);
    }
  }

  global.canvasLayer0 = canvasLayer0;
})(this);