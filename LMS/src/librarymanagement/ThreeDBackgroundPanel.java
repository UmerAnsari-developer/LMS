package librarymanagement;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.GradientPaint;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Point;
import java.awt.RenderingHints;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.geom.Ellipse2D;
import java.awt.geom.Line2D;
import java.awt.geom.Path2D;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

import javax.swing.JPanel;
import javax.swing.Timer;

/**
 * Lightweight, dependency-free 3D-style background for the desktop shell.
 * The effect is rendered with Java2D so it works with the existing Swing app
 * and does not require OpenGL or additional libraries.
 */
public class ThreeDBackgroundPanel extends JPanel {
    private static final int PARTICLE_COUNT = 72;
    private static final int SHAPE_COUNT = 10;
    private static final int FOCAL_LENGTH = 520;
    private static final Color NAVY = new Color(7, 16, 35);
    private static final Color BLUE = new Color(74, 170, 255);
    private static final Color CYAN = new Color(72, 226, 218);
    private static final Color PURPLE = new Color(145, 113, 255);

    private final Random random = new Random(42);
    private final List<Particle> particles = new ArrayList<>();
    private final List<WireShape> shapes = new ArrayList<>();
    private final Point mouse = new Point();
    private final Timer animationTimer;
    private double time;
    private double tiltX;
    private double tiltY;

    public ThreeDBackgroundPanel() {
        setOpaque(true);
        setLayout(null);
        setBackground(NAVY);
        setFocusable(false);

        for (int i = 0; i < PARTICLE_COUNT; i++) {
            particles.add(new Particle());
        }
        for (int i = 0; i < SHAPE_COUNT; i++) {
            shapes.add(new WireShape());
        }

        addMouseMotionListener(new MouseAdapter() {
            @Override
            public void mouseMoved(MouseEvent event) {
                updateMouse(event);
            }

            @Override
            public void mouseDragged(MouseEvent event) {
                updateMouse(event);
            }

            private void updateMouse(MouseEvent event) {
                mouse.setLocation(event.getPoint());
                double centerX = Math.max(1, getWidth() / 2.0);
                double centerY = Math.max(1, getHeight() / 2.0);
                tiltY = (event.getX() - centerX) / centerX;
                tiltX = (event.getY() - centerY) / centerY;
            }
        });

        animationTimer = new Timer(32, event -> {
            time += 0.018;
            for (Particle particle : particles) particle.advance();
            for (WireShape shape : shapes) shape.advance();
            repaint();
        });
        animationTimer.setCoalesce(true);
        animationTimer.start();
    }

    @Override
    protected void paintComponent(Graphics graphics) {
        super.paintComponent(graphics);
        if (getWidth() <= 0 || getHeight() <= 0) return;

        Graphics2D g = (Graphics2D) graphics.create();
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_SPEED);

        drawAtmosphere(g);
        drawPerspectiveGrid(g);
        drawWireShapes(g);
        drawParticles(g);
        drawCursorGlow(g);
        g.dispose();
    }

    private void drawAtmosphere(Graphics2D g) {
        int w = getWidth();
        int h = getHeight();
        g.setPaint(new GradientPaint(0, 0, new Color(5, 12, 28), w, h, new Color(13, 30, 62)));
        g.fillRect(0, 0, w, h);

        float glowX = (float) (w * 0.73 + tiltY * 55);
        float glowY = (float) (h * 0.18 + tiltX * 35);
        int radius = Math.max(w, h) / 2;
        g.setPaint(new GradientPaint(glowX - radius, glowY, new Color(35, 105, 210, 45), glowX + radius, glowY, new Color(35, 105, 210, 0)));
        g.fill(new Ellipse2D.Double(glowX - radius, glowY - radius, radius * 2.0, radius * 2.0));

        g.setColor(new Color(255, 255, 255, 7));
        for (int y = 0; y < h; y += 4) {
            g.drawLine(0, y, w, y);
        }
    }

    private void drawPerspectiveGrid(Graphics2D g) {
        int w = getWidth();
        int h = getHeight();
        double horizon = h * 0.58 + tiltX * 12;
        double vanishingX = w * 0.5 + tiltY * 80;

        g.setStroke(new BasicStroke(1f));
        for (int i = -16; i <= 16; i++) {
            double bottomX = vanishingX + i * w * 0.095;
            g.setColor(new Color(69, 175, 255, i % 2 == 0 ? 22 : 12));
            g.draw(new Line2D.Double(vanishingX, horizon, bottomX, h + 20));
        }
        for (int i = 1; i <= 14; i++) {
            double progress = i / 14.0;
            double y = horizon + Math.pow(progress, 1.8) * (h - horizon + 30);
            int alpha = (int) (8 + progress * 18);
            g.setColor(new Color(72, 226, 218, alpha));
            g.draw(new Line2D.Double(0, y, w, y));
        }
        g.setColor(new Color(83, 189, 255, 70));
        g.setStroke(new BasicStroke(2f));
        g.draw(new Line2D.Double(0, horizon, w, horizon));
    }

    private void drawWireShapes(Graphics2D g) {
        for (WireShape shape : shapes) {
            Projection p = project(shape.x, shape.y, shape.z);
            if (p == null) continue;
            int size = Math.max(8, (int) (shape.size * p.scale));
            g.setColor(new Color(shape.color.getRed(), shape.color.getGreen(), shape.color.getBlue(), (int) (shape.alpha * p.scale)));
            g.setStroke(new BasicStroke(1.1f));
            Path2D path = new Path2D.Double();
            for (int i = 0; i <= shape.sides; i++) {
                double angle = shape.rotation + i * Math.PI * 2 / shape.sides;
                double x = p.x + Math.cos(angle) * size;
                double y = p.y + Math.sin(angle) * size * 0.62;
                if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
            }
            g.draw(path);
            g.setColor(new Color(shape.color.getRed(), shape.color.getGreen(), shape.color.getBlue(), 18));
            g.fill(path);
        }
    }

    private void drawParticles(Graphics2D g) {
        List<Projection> projected = new ArrayList<>();
        for (Particle particle : particles) {
            Projection p = project(particle.x, particle.y, particle.z);
            if (p != null) projected.add(p.with(particle));
        }
        for (int i = 0; i < projected.size(); i++) {
            Projection a = projected.get(i);
            for (int j = i + 1; j < projected.size(); j++) {
                Projection b = projected.get(j);
                double distance = a.distanceTo(b);
                if (distance < 92) {
                    int alpha = (int) (28 * (1 - distance / 92));
                    g.setColor(new Color(83, 190, 255, alpha));
                    g.setStroke(new BasicStroke(0.6f));
                    g.draw(new Line2D.Double(a.x, a.y, b.x, b.y));
                }
            }
        }
        for (Projection p : projected) {
            int radius = Math.max(1, (int) (p.particle.size * p.scale));
            Color c = p.particle.color;
            g.setColor(new Color(c.getRed(), c.getGreen(), c.getBlue(), Math.min(180, (int) (p.particle.alpha * p.scale))));
            g.fill(new Ellipse2D.Double(p.x - radius, p.y - radius, radius * 2.0, radius * 2.0));
            if (radius > 2) {
                g.setColor(new Color(c.getRed(), c.getGreen(), c.getBlue(), 26));
                g.fill(new Ellipse2D.Double(p.x - radius * 3, p.y - radius * 3, radius * 6.0, radius * 6.0));
            }
        }
    }

    private void drawCursorGlow(Graphics2D g) {
        if (!contains(mouse)) return;
        int radius = 105;
        g.setPaint(new GradientPaint(mouse.x - radius, mouse.y, new Color(72, 226, 218, 35), mouse.x + radius, mouse.y, new Color(72, 226, 218, 0)));
        g.fill(new Ellipse2D.Double(mouse.x - radius, mouse.y - radius, radius * 2.0, radius * 2.0));
    }

    private Projection project(double x, double y, double z) {
        double rotatedX = x + tiltY * z * 0.10;
        double rotatedY = y + tiltX * z * 0.06;
        double scale = FOCAL_LENGTH / (FOCAL_LENGTH + z);
        return new Projection(getWidth() / 2.0 + rotatedX * scale, getHeight() * 0.48 + rotatedY * scale, scale, null);
    }

    @Override
    public void removeNotify() {
        animationTimer.stop();
        super.removeNotify();
    }

    private final class Particle {
        double x = (random.nextDouble() - 0.5) * 1300;
        double y = (random.nextDouble() - 0.5) * 720;
        double z = 40 + random.nextDouble() * 920;
        double speed = 0.25 + random.nextDouble() * 0.7;
        double size = 1.2 + random.nextDouble() * 2.8;
        double alpha = 90 + random.nextDouble() * 100;
        Color color = random.nextBoolean() ? BLUE : (random.nextBoolean() ? CYAN : PURPLE);

        void advance() {
            z -= speed;
            if (z < 18) {
                z = 960;
                x = (random.nextDouble() - 0.5) * 1300;
                y = (random.nextDouble() - 0.5) * 720;
            }
        }
    }

    private final class WireShape {
        double x = (random.nextDouble() - 0.5) * 1150;
        double y = (random.nextDouble() - 0.5) * 580;
        double z = 180 + random.nextDouble() * 700;
        double size = 22 + random.nextDouble() * 44;
        double rotation = random.nextDouble() * Math.PI;
        double rotationSpeed = (random.nextDouble() - 0.5) * 0.01;
        int sides = 3 + random.nextInt(4);
        int alpha = 35 + random.nextInt(25);
        Color color = random.nextBoolean() ? BLUE : PURPLE;

        void advance() {
            z -= 0.18;
            rotation += rotationSpeed;
            if (z < 70) z = 850;
        }
    }

    private static final class Projection {
        final double x;
        final double y;
        final double scale;
        final Particle particle;

        Projection(double x, double y, double scale, Particle particle) {
            this.x = x;
            this.y = y;
            this.scale = scale;
            this.particle = particle;
        }

        Projection with(Particle value) {
            return new Projection(x, y, scale, value);
        }

        double distanceTo(Projection other) {
            return Math.hypot(x - other.x, y - other.y);
        }
    }
}

