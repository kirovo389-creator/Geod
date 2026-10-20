#include <Geode/Geode.hpp>
#include <Geode/modify/PlayLayer.hpp>

using namespace geode::prelude;

namespace {
    constexpr int kSpikeObjectId = 8;
    constexpr float kLookAhead = 110.f;
    constexpr float kJumpTriggerDistance = 78.f;

    bool shouldDraw() {
        return Mod::get()->getSettingValue<bool>("show-trajectories");
    }

    bool autoJumpEnabled() {
        return Mod::get()->getSettingValue<bool>("enabled");
    }
}

class $modify(DualMindPlayLayer, PlayLayer) {
    struct Fields {
        CCDrawNode* lines = nullptr;
        bool releaseNextFrame = false;
        float jumpCooldown = 0.f;
    };

    bool init(GJGameLevel* level, bool useReplay, bool dontCreateObjects) {
        if (!PlayLayer::init(level, useReplay, dontCreateObjects)) {
            return false;
        }

        m_fields->lines = CCDrawNode::create();
        if (m_fields->lines) {
            m_fields->lines->setID("dualmind-trajectory-lines");
            this->addChild(m_fields->lines, 1000);
        }

        log::info("DualMind loaded for Geometry Dash 2.2081 (experimental)");
        return true;
    }

    void postUpdate(float dt) {
        PlayLayer::postUpdate(dt);

        if (!m_player1 || m_player1->m_isDead) {
            clearLines();
            return;
        }

        if (m_fields->jumpCooldown > 0.f) {
            m_fields->jumpCooldown = std::max(0.f, m_fields->jumpCooldown - dt);
        }

        if (m_fields->releaseNextFrame) {
            this->handleButton(false, 1, true);
            m_fields->releaseNextFrame = false;
        }

        drawPredictions();

        if (!autoJumpEnabled() || !m_player1->m_isOnGround ||
            m_fields->jumpCooldown > 0.f || m_fields->releaseNextFrame) {
            return;
        }

        // Prototype planner: only recognizes standard spike objects.
        float nearest = kLookAhead + 1.f;
        const float playerX = m_player1->getPositionX();

        for (auto* object : CCArrayExt<GameObject>(m_objects)) {
            if (!object || object->m_isDisabled || object->m_objectID != kSpikeObjectId) {
                continue;
            }

            const float dx = object->getPositionX() - playerX;
            if (dx > 0.f && dx < nearest) {
                nearest = dx;
            }
        }

        if (nearest <= kJumpTriggerDistance) {
            this->handleButton(true, 1, true);
            m_fields->releaseNextFrame = true;
            m_fields->jumpCooldown = 0.20f;
        }
    }

    void clearLines() {
        if (m_fields->lines) {
            m_fields->lines->clear();
        }
    }

    void drawPredictions() {
        if (!m_fields->lines || !shouldDraw()) {
            clearLines();
            return;
        }

        m_fields->lines->clear();
        const CCPoint start = m_player1->getPosition();
        const float vy = m_player1->m_yVelocity;
        CCPoint previousA = start;
        CCPoint previousB = start;
        constexpr float stepX = 9.f;
        constexpr float gravityA = -0.72f;
        constexpr float gravityB = -0.88f;
        constexpr float frames = 12.f;

        for (int i = 1; i <= 10; ++i) {
            const float t = static_cast<float>(i) * frames / 10.f;
            CCPoint nextA(start.x + stepX * t, start.y + vy * t + 0.5f * gravityA * t * t);
            CCPoint nextB(start.x + stepX * t, start.y + vy * t + 0.5f * gravityB * t * t);
            m_fields->lines->drawSegment(previousA, nextA, 1.5f, ccc4f(0.15f, 0.75f, 1.f, 0.9f));
            m_fields->lines->drawSegment(previousB, nextB, 1.5f, ccc4f(1.f, 0.65f, 0.15f, 0.9f));
            previousA = nextA;
            previousB = nextB;
        }
    }
};
