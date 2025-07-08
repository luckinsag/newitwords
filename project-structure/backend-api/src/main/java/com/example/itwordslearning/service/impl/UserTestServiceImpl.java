package com.example.itwordslearning.service.impl;

import com.example.itwordslearning.dto.UserTestRecordDTO;
import com.example.itwordslearning.entity.UserTest;
import com.example.itwordslearning.mapper.UserTestMapper;
import com.example.itwordslearning.service.UserTestService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Date; // 确保导入 java.util.Date 或 java.time.LocalDateTime

@Service
public class UserTestServiceImpl implements UserTestService {

    @Autowired
    private UserTestMapper userTestMapper;

    @Override
    public Integer insertUserTestAndReturnSessionId(UserTestRecordDTO dto) {
        UserTest test = new UserTest();
        test.setUserId(dto.getUserId());

        // *** 关键修改：添加对 endedAt 的 null 检查和默认值设置 ***
        if (dto.getEndedAt() != null) {
            test.setEndedAt(dto.getEndedAt());
        } else {
            // 如果 DTO 中没有提供 endedAt，或者其值为 null，则使用当前时间
            test.setEndedAt(new Date()); // 使用当前时间
            // 如果你的 UserTest 实体中的 endedAt 是 LocalDateTime 类型，请使用：
            // test.setEndedAt(java.time.LocalDateTime.now());
        }
        // ************************************************************

        test.setScore(dto.getScore());

        userTestMapper.insertUserTest(test);
        return userTestMapper.getLastSessionId();
    }
}